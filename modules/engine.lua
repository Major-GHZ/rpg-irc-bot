-- Modules de jeu
local Level = require("modules.level")
local CreateCharacter = require("modules.character")
local xml = require("modules.character_xml")

-- Modules IRC
local socket = require("socket")
local json = require("dkjson")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")

-- État pour la création de personnage via IRC
local character_creation_state = {}

-- ======================
-- Logique de jeu (locale)
-- ======================
local function run_game_example()
    local game = Level.new()
    local create = CreateCharacter.new()
    local character = create:newCharacter()

    print("\n--- Summary ---")
    print("Name: " .. character.name)
    print("Class: " .. character.class)
    print("Level: " .. character.level)
    print("Attributes:")
    print("- Intelligence: " .. character.attributes.intelligence)
    print("- Strength: " .. character.attributes.strength)
    print("- Dexterity: " .. character.attributes.dexterity)
    print("- Endurance: " .. character.attributes.endurance)
    print("Spells: " .. table.concat(character.spells, ", "))

    xml.sauvegarder_personnage(character)

    local hero = { energy = 100, energieMax = 100 }
    local boss = { energy = 1000, energieMax = 1000 }

    game:newDamage(hero, 5)
    print("Hero Energy", hero.energy)
    game:newDamage(boss, 45)
    print("Boss Energy", boss.energy)
end

local function run_character_creation()
    local create = CreateCharacter.new()
    print("\n--- Création de personnage ---")
    local character = create:createCharacterInteractive()

    print("\n--- Personnage créé ---")
    print("Nom : " .. character.name)
    print("Classe : " .. character.class)
    print("Niveau : " .. character.level)
    print("Attributs :")
    print("- Intelligence : " .. character.attributes.intelligence)
    print("- Force : " .. character.attributes.strength)
    print("- Dextérité : " .. character.attributes.dexterity)
    print("- Endurance : " .. character.attributes.endurance)
    print("Sorts : " .. table.concat(character.spells, ", "))

    xml.sauvegarder_personnage(character)

    return character
end

-- ======================
-- Logique IRC
-- ======================
local irc_server = "irc.oftc.net"
local irc_port = 6667
local nickname = "lua_bot_" .. os.time()
local default_channel = "#monbot"
local reconnect_delay = 10
local connection_timeout = 30
local receive_timeout = 5
local current_channel = default_channel

local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

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

local function handle_character_creation(irc, sender_nick, channel, msg)
    if not character_creation_state[sender_nick] then
        character_creation_state[sender_nick] = {
            step = 1,
            character = {}
        }
    end

    local state = character_creation_state[sender_nick]

    if state.step == 1 then
        state.character.name = msg
        irc:PRIVMSG(channel, sender_nick .. ", choisissez une classe (Guerrier/Mage/Voleur) :")
        state.step = 2
    elseif state.step == 2 then
        local class = msg:lower()
        if class == "guerrier" then
            state.character.class = "Guerrier"
            state.character.attributes = {intelligence = 5, strength = 10, dexterity = 7, endurance = 12}
            state.character.spells = {"Coup puissant", "Cri de guerre"}
        elseif class == "mage" then
            state.character.class = "Mage"
            state.character.attributes = {intelligence = 12, strength = 5, dexterity = 7, endurance = 8}
            state.character.spells = {"Boule de feu", "Soin", "Téléportation"}
        elseif class == "voleur" then
            state.character.class = "Voleur"
            state.character.attributes = {intelligence = 7, strength = 7, dexterity = 12, endurance = 8}
            state.character.spells = {"Vol", "Attaque sournoise", "Disparition"}
        else
            state.character.class = "Aventurier"
            state.character.attributes = {intelligence = 8, strength = 8, dexterity = 8, endurance = 8}
            state.character.spells = {"Attaque basique"}
        end
        irc:PRIVMSG(channel, sender_nick .. ", entrez le niveau (1-10) :")
        state.step = 3
    elseif state.step == 3 then
        state.character.level = tonumber(msg) or 1
        state.character.level = math.min(10, math.max(1, state.character.level))

        local response = string.format(
            "%s, ton personnage a été créé : %s (Niveau %d, %s). Attributs: Int=%d, Str=%d, Dex=%d, End=%d. Sorts: %s",
            sender_nick,
            state.character.name,
            state.character.level,
            state.character.class,
            state.character.attributes.intelligence,
            state.character.attributes.strength,
            state.character.attributes.dexterity,
            state.character.attributes.endurance,
            table.concat(state.character.spells, ", ")
        )
        irc:PRIVMSG(channel, response)
        xml.sauvegarder_personnage(state.character)
        character_creation_state[sender_nick] = nil
    end
end

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

                if msg:lower():match("^!salut") then
                    irc:PRIVMSG(current_channel, "Salut, it's my fire hello world!")
                elseif msg:lower():match("^!ping") then
                    irc:PRIVMSG(current_channel, "Pong!")
                elseif msg:lower():match("^!create") then
                    local sender_nick = sender[1]
                    irc:PRIVMSG(current_channel, sender_nick .. ", entrez le nom de votre personnage :")
                    character_creation_state[sender_nick] = {
                        step = 1,
                        character = {}
                    }
                elseif character_creation_state[sender[1]] then
                    handle_character_creation(irc, sender[1], current_channel, msg)
                end
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

-- ======================
-- Export public
-- ======================
return {
    run_game_example = run_game_example,
    run_character_creation = run_character_creation,
    run_irc_bot = run_irc_bot,
}

