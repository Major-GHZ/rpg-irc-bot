-- engine.lua

-- ======================
-- Modules de jeu
-- ======================
local Stage = require("modules.stage")
local CreateCharacter = require("modules.character")
local xml = require("modules.character_xml")

-- ======================
-- Logique de jeu
-- ======================
local function run_game_example()
    local game = Stage.new()
    local create = CreateCharacter.new()
    local character = create:newCharacter()

    -- Print character summary
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

    -- Sauvegarde XML
    xml.sauvegarder_personnage(character)

    -- Exemple de combat
    local hero = { energy = 100, energieMax = 100 }
    local boss = { energy = 1000, energieMax = 1000 }

    game:newDamage(hero, 5)
    print("Hero Energy", hero.energy)
    game:newDamage(boss, 45)
    print("Boss Energy", boss.energy)
    game:newDamage(hero, 5)
    print("Hero Energy", hero.energy)
    game:newDamage(boss, 45)
    print("Boss Energy", boss.energy)
    game:newDamage(hero, 5)
    print("Hero Energy", hero.energy)
    game:newDamage(boss, 45)
    print("Boss Energy", boss.energy)
end

-- ======================
-- Logique IRC
-- ======================
local socket = require("socket")
local json = require("dkjson")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")

-- Configuration IRC
local irc_server = "irc.oftc.net"
local irc_port = 6667
local nickname = "lua_bot_" .. os.time()
local default_channel = "#monbot"
local reconnect_delay = 10
local connection_timeout = 30
local receive_timeout = 5
local current_channel = default_channel

-- Logger
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Connexion IRC
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

-- Boucle principale IRC
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

            -- Callbacks
            irc:set_callback("PRIVMSG", function(_, sender, origin, msg)
                log(string.format("<%s> %s", sender[1], msg))
                if origin:sub(1, 1) == "#" then current_channel = origin end

                if msg:lower():match("^!salut") then
                    irc:PRIVMSG(current_channel, "Salut, it's my fire hello world!")
                elseif msg:lower():match("^!ping") then
                    irc:PRIVMSG(current_channel, "Pong!")
                end
            end)

            irc:set_callback("PING", function(_, _, params)
                irc:PONG(params[1])
                log("PONG envoyé en réponse à PING.")
            end)

            irc:set_callback("ERROR", function(_, err)
                log("Erreur IRC: " .. tostring(err))
            end)

            -- Connexion et identification
            irc:NICK(nickname)
            irc:USER(nickname, "0", "*", ":Lua Bot")
            irc:JOIN(default_channel)
            log("Bot IRC prêt et connecté à " .. default_channel)

            -- Boucle IRC
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
    run_irc_bot = run_irc_bot,
}

