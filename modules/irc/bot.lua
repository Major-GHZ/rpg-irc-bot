-- Ajoute le chemin des modules Lua
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Modules de jeu
local Character = require("character")
local xml = require("character_xml")

-- Modules IRC
local socket = require("socket")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")

-- État pour la création de personnage via IRC
local character_creation_state = {}
local characters = {}

-- Configuration IRC
local irc_server = "irc.oftc.net"
local irc_port = 6667
local nickname = "lua_bot_" .. os.time()
local default_channel = "#monbot"
local reconnect_delay = 10
local connection_timeout = 30
local receive_timeout = 5
local current_channel = default_channel

-- Journalisation
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Connexion au serveur IRC
local function connect_to_irc()
    log("Tentative de connexion à " .. irc_server .. ":" .. irc_port)
    local client = socket.tcp()
    client:settimeout(connection_timeout)
    local success, err = client:connect(irc_server, irc_port)
    if not success then
        log("Erreur de connexion IRC: " .. tostring(err))
        client:close()
        return nil
    end
    log("Connecté au serveur IRC avec succès!")
    client:settimeout(receive_timeout)
    return client
end

-- Affiche le récapitulatif d'un personnage
local function show_character_recap(irc, sender_nick, channel)
    if characters[sender_nick] then
        local character = characters[sender_nick]
        local recap = string.format(
            "%s, récapitulatif de ton personnage : %s (%s, Niveau %d). Attributs: Int=%d, For=%d, Dex=%d, End=%d, Mag=%d. Sorts: %s. Énergie: %d/%d",
            sender_nick,
            character.name,
            character.class,
            character.level,
            character.attributes.intelligence,
            character.attributes.strength,
            character.attributes.dexterity,
            character.attributes.endurance,
            character.attributes.magic,
            table.concat(character.spells, ", "),
            character.energy,
            character.energieMax
        )
        irc:PRIVMSG(channel, recap)
    else
        irc:PRIVMSG(channel, sender_nick .. ", tu n'as pas encore créé de personnage.")
    end
end

-- Fonction pour demander un attribut spécifique
local function ask_for_attribute(irc, sender_nick, channel, attribute, state)
    state.step = state.step + 1
    irc:PRIVMSG(channel, sender_nick .. ", entrez la valeur pour " .. attribute .. " (max " .. state.points_restants .. ", points restants: " .. state.points_restants .. ") :")
end

-- Gestion de la création de personnage
local function handle_character_creation(irc, sender_nick, channel, msg)
    if not character_creation_state[sender_nick] then
        return false
    end

    local state = character_creation_state[sender_nick]

    if state.step == 1 then
        state.character.name = msg
        irc:PRIVMSG(channel, sender_nick .. ", choisissez une classe (Guerrier/Mage/Voleur/Aventurier) :")
        state.step = 2
    elseif state.step == 2 then
        state.character.class = msg:lower()
        state.character.attributes = {}
        state.points_restants = 30
        irc:PRIVMSG(channel, sender_nick .. ", vous avez 30 points à répartir entre vos attributs.")
        ask_for_attribute(irc, sender_nick, channel, "intelligence", state)
    elseif state.step == 3 then  -- Intelligence
        local int = tonumber(msg)
        if not int or int < 0 or int > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", valeur invalide pour l'intelligence (max " .. state.points_restants .. "). Réessayez :")
            return true
        end
        state.character.attributes.intelligence = int
        state.points_restants = state.points_restants - int
        ask_for_attribute(irc, sender_nick, channel, "force", state)
    elseif state.step == 4 then  -- Force
        local for_ = tonumber(msg)
        if not for_ or for_ < 0 or for_ > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", valeur invalide pour la force (max " .. state.points_restants .. "). Réessayez :")
            return true
        end
        state.character.attributes.strength = for_
        state.points_restants = state.points_restants - for_
        ask_for_attribute(irc, sender_nick, channel, "dexterité", state)
    elseif state.step == 5 then  -- Dextérité
        local dex = tonumber(msg)
        if not dex or dex < 0 or dex > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", valeur invalide pour la dexterité (max " .. state.points_restants .. "). Réessayez :")
            return true
        end
        state.character.attributes.dexterity = dex
        state.points_restants = state.points_restants - dex
        ask_for_attribute(irc, sender_nick, channel, "endurance", state)
    elseif state.step == 6 then  -- Endurance
        local end_ = tonumber(msg)
        if not end_ or end_ < 0 or end_ > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", valeur invalide pour l'endurance (max " .. state.points_restants .. "). Réessayez :")
            return true
        end
        state.character.attributes.endurance = end_
        state.character.attributes.magic = state.points_restants - end_
        irc:PRIVMSG(channel, sender_nick .. ", il vous reste " .. (state.points_restants - end_) .. " points pour la magie.")
        irc:PRIVMSG(channel, sender_nick .. ", entrez le niveau (1-10) :")
        state.step = 7
    elseif state.step == 7 then  -- Niveau
        local level = tonumber(msg) or 1
        level = math.max(1, math.min(10, level))
        state.character.level = level

        local character = Character:createCharacterWithAttributes(
            state.character.name,
            state.character.class,
            state.character.level,
            state.character.attributes
        )

        local recap = string.format(
            "%s, ton personnage a été créé : %s (%s, Niveau %d). Attributs: Int=%d, For=%d, Dex=%d, End=%d, Mag=%d. Sorts: %s",
            sender_nick,
            character.name,
            character.class,
            character.level,
            character.attributes.intelligence,
            character.attributes.strength,
            character.attributes.dexterity,
            character.attributes.endurance,
            character.attributes.magic,
            table.concat(character.spells, ", ")
        )
        irc:PRIVMSG(channel, recap)
        xml.sauvegarder_personnage(character)
        characters[sender_nick] = character
        character_creation_state[sender_nick] = nil
    end

    return true
end

-- Démarre la création de personnage
local function start_character_creation(irc, sender_nick, channel)
    character_creation_state[sender_nick] = {
        step = 1,
        character = {}
    }
    irc:PRIVMSG(channel, sender_nick .. ", entrez le nom de votre personnage :")
end

-- Gestion des commandes IRC
local function handle_irc_command(irc, sender_nick, channel, msg)
    if msg:lower():match("^!create") then
        start_character_creation(irc, sender_nick, channel)
    elseif msg:lower():match("^!recap") then
        show_character_recap(irc, sender_nick, channel)
    elseif msg:lower():match("^!ping") then
        irc:PRIVMSG(channel, "Pong!")
    elseif msg:lower():match("^!salut") then
        irc:PRIVMSG(channel, "Salut, " .. sender_nick .. " !")
    elseif msg:lower():match("^!help") then
        irc:PRIVMSG(channel, "Commandes disponibles : !create, !recap, !ping, !salut, !help")
    elseif character_creation_state[sender_nick] then
        handle_character_creation(irc, sender_nick, channel, msg)
    end
end

-- Lancement du bot IRC
local function run_irc_bot()
    while true do
        local irc_client = connect_to_irc()
        if not irc_client then
            log("Échec de la connexion. Nouvelle tentative dans " .. reconnect_delay .. " secondes...")
            socket.sleep(reconnect_delay)
        else
            local irc = IRCe.new()
            irc:load_module(mod_base)
            irc:load_module(mod_message)
            irc:load_module(mod_channel)

            irc:set_send_func(function(_, message)
                local success, err = irc_client:send(message .. "\r\n")
                if not success then
                    log("Erreur d'envoi: " .. tostring(err))
                    return false
                end
                return true
            end)

            irc:set_callback("PRIVMSG", function(_, sender, origin, msg)
                log(string.format("<%s> %s", sender[1], msg))
                if origin:sub(1, 1) == "#" then current_channel = origin end
                handle_irc_command(irc, sender[1], current_channel, msg)
            end)

            irc:set_callback("PING", function(_, _, params)
                irc:PONG(params[1])
                log("PONG envoyé en réponse à PING.")
            end)

            irc:set_callback("ERROR", function(_, err)
                log("Erreur IRC: " .. tostring(err))
            end)

            irc:NICK(nickname)
            irc:USER(nickname, "0", "*", ":Lua Bot")
            irc:JOIN(default_channel)
            log("Bot IRC prêt et connecté à " .. default_channel)

            local last_ping_time = socket.gettime()
            while true do
                local line, err = irc_client:receive()
                if not line then
                    if err ~= "timeout" then
                        log("Déconnecté du serveur IRC: " .. (err or "unknown"))
                        irc_client:close()
                        break
                    end
                else
                    irc:process(line)
                end

                if socket.gettime() - last_ping_time > 60 then
                    irc:PING(irc_server)
                    last_ping_time = socket.gettime()
                end
                socket.sleep(0.01)
            end
        end
    end
end

-- Point d'entrée
return {
    run_irc_bot = run_irc_bot
}
