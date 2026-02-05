local socket = require("socket")
local json = require("dkjson")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")

-- Configuration
local game_host = "127.0.0.1"
local game_port = 12345
local irc_server = "irc.libera.chat"
local irc_port = 6667
local nickname = "lua_bot"
local default_channel = "#monbot"
local reconnect_delay = 3  -- Délai de reconnexion en secondes
local message_interval = 3  -- Intervalle entre les messages (3 secondes)

-- Variable globale pour le canal IRC actuel
local current_channel = default_channel

-- Fonction pour logger avec timestamp
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Simuler les modules de jeu
local Stage = { new = function() return { newDamage = function(_, target, amount) target.energy = target.energy - amount end } end }
local CreateCharacter = {
    new = function()
        return {
            newCharacter = function(_, name, char_class)
                return {
                    name = name or "Unknown",
                    class = char_class or "Warrior",
                    level = 1,
                    attributes = { intelligence = 10, strength = 10, dexterity = 10, endurance = 10 },
                    spells = {"Fireball", "Heal"}
                }
            end
        }
    end
}
local xml = { sauvegarder_personnage = function(_) log("Personnage sauvegardé (simulé).") end }

-- Initialisation du jeu
local game = Stage.new()
local create = CreateCharacter.new()
local hero = { energy = 100, energieMax = 100 }
local boss = { energy = 1000, energieMax = 1000 }

-- Fonction pour créer un personnage
local function create_character(name, char_class)
    local character = create:newCharacter(name, char_class)
    xml.sauvegarder_personnage(character)
    return character
end

-- Fonction pour gérer la logique de jeu (serveur local)
local function run_game_server()
    local server = assert(socket.bind(game_host, game_port))
    server:settimeout(3)
    assert(server:listen(1))
    log("Serveur de jeu démarré sur le port " .. game_port)

    while true do
        local client = server:accept()
        client:settimeout(3)
        log("Bot IRC connecté au serveur de jeu.")

        while true do
            local line, err = client:receive()
            if not line then
                log("Erreur ou déconnexion du bot IRC: " .. (err or "unknown"))
                client:close()
                break
            end

            local command = json.decode(line)
            if command.type == "command" then
                log("Commande reçue: " .. command.text)
                if command.text:lower():match("^!create") then
                    local _, _, name, char_class = command.text:find("^!create (%S+) (%S+)")
                    if name and char_class then
                        local character = create_character(name, char_class)
                        client:send(json.encode({
                            type = "character_created",
                            name = character.name,
                            class = character.class,
                            level = character.level,
                            attributes = character.attributes,
                            spells = character.spells
                        }) .. "\n")
                    else
                        client:send(json.encode({
                            type = "error",
                            message = "Usage: !create <nom> <classe>"
                        }) .. "\n")
                    end
                elseif command.text:lower():match("^!attack") then
                    game:newDamage(boss, 45)
                    client:send(json.encode({
                        type = "game_update",
                        hero_energy = hero.energy,
                        boss_energy = boss.energy
                    }) .. "\n")
                end
            end
        end
    end
end

-- Fonction pour se connecter au serveur IRC
local function connect_to_irc()
    log("Tentative de connexion à " .. irc_server .. ":" .. irc_port)
    local client = socket.tcp()
    client:settimeout(3)
    local success, err = client:connect(irc_server, irc_port)
    if not success then
        log("Erreur de connexion IRC: " .. tostring(err))
        client:close()
        return nil
    end
    log("Connecté au serveur IRC avec succès!")
    return client
end

-- Fonction pour exécuter le bot IRC
local function run_irc_bot()
    while true do
        local irc_client = connect_to_irc()
        if not irc_client then
            log("Reconnexion dans " .. reconnect_delay .. " secondes...")
            socket.sleep(reconnect_delay)
        end

        local game_client = socket.tcp()
        game_client:settimeout(3)
        local success, err = game_client:connect(game_host, game_port)
        if not success then
            log("Erreur de connexion au serveur de jeu: " .. tostring(err))
            game_client:close()
        else
            log("Connecté au serveur de jeu.")
        end

        local irc = IRCe.new()
        irc:load_module(mod_base)
        irc:load_module(mod_message)
        irc:load_module(mod_channel)

        irc:set_send_func(function(_, message)
            -- log(">> " .. message)  -- Désactivé pour éviter le spam
            return irc_client:send(message .. "\r\n")
        end)

        irc:set_callback("PRIVMSG", function(_, sender, origin, msg)
            log(string.format("<%s> %s", sender[1], msg))
            if origin:sub(1, 1) == "#" then current_channel = origin end

            if msg:lower():match("^!salut") then
                irc:PRIVMSG(current_channel, "Salut! Je suis un bot de jeu. Utilise !create <nom> <classe> pour créer un personnage.")
            elseif msg:lower():match("^!create") and game_client then
                game_client:send(json.encode({ type = "command", text = msg }) .. "\n")
            elseif msg:lower():match("^!attack") and game_client then
                game_client:send(json.encode({ type = "command", text = "!attack" }) .. "\n")
                irc:PRIVMSG(current_channel, "Attaque lancée!")
            end
        end)

        irc:set_callback("JOIN", function(_, sender, channel)
            if sender[1] == nickname then
                current_channel = channel
                log("Rejoint le canal: " .. current_channel)
            end
        end)

        -- Répondre aux PING du serveur
        irc:set_callback("PING", function(_, _, params)
            irc:PONG(params[1])
        end)

        -- Callback pour les messages RAW (filtrer les messages non critiques)
        irc:set_callback(IRCe.RAW, function(_, send, msg)
            if not send then
                if not msg:match("^:%S+ NOTICE ") and
                   not msg:match("^:%S+ MODE ") and
                   not msg:match("^:%S+ %d+ $") and
                   not msg:match("^PING ") then  -- Filtrer aussi les PING reçus
                    log("<< " .. msg)
                end
            end
        end)

        -- Connexion IRC
        irc:NICK(nickname)
        irc:USER(nickname, "0", "*", ":Lua Bot")
        irc:JOIN(default_channel)

        -- Temps du dernier message envoyé
        local last_message_time = socket.gettime()

        irc_client:settimeout(3)
        while true do
            local line, err = irc_client:receive()
            if not line then
                log("Déconnecté du serveur IRC: " .. (err or "unknown"))
                irc_client:close()
                if game_client then game_client:close() end
                break
            end
            irc:process(line)

            -- Envoyer un PING toutes les 3 secondes pour maintenir la connexion (sans log)
            if socket.gettime() - last_message_time > message_interval then
                irc:PING(irc_server)
                last_message_time = socket.gettime()
            end

            if game_client then
                local game_line, game_err = game_client:receive()
                if game_line then
                    local response = json.decode(game_line)
                    if response.type == "character_created" then
                        irc:PRIVMSG(current_channel, string.format(
                            "Personnage créé: %s (%s), niveau %d. Attributs: Int:%d Str:%d Dex:%d End:%d. Sortilèges: %s",
                            response.name, response.class, response.level,
                            response.attributes.intelligence, response.attributes.strength,
                            response.attributes.dexterity, response.attributes.endurance,
                            table.concat(response.spells, ", ")
                        ))
                    elseif response.type == "error" then
                        irc:PRIVMSG(current_channel, response.message)
                    elseif response.type == "game_update" then
                        irc:PRIVMSG(current_channel, string.format(
                            "État du jeu: Héros %d/%d, Boss %d/%d",
                            response.hero_energy, hero.energieMax,
                            response.boss_energy, boss.energieMax
                        ))
                    end
                elseif game_err and game_err ~= "timeout" then
                    log("Erreur de réception du serveur de jeu: " .. game_err)
                    game_client:close()
                    game_client = nil
                end
            end
            socket.sleep(0.1)
        end
    end
end

-- Lancer le serveur de jeu dans un thread séparé
local co = coroutine.create(run_game_server)
coroutine.resume(co)

-- Lancer le bot IRC
log("Démarrage du bot IRC...")
run_irc_bot()

