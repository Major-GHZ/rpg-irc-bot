local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")
local luasocket = require("socket")

-- Configuration
local server = "irc.libera.chat"
local port = 6667
local nickname = "lua_bot"
local default_channel = "#gamecodeur"  -- Canal par défaut
local reconnect_delay = 10
local response_message = "salut! it's my first hello world"

-- Variable globale pour stocker le canal actuel
local current_channel = default_channel

-- Fonction pour logger avec timestamp
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Fonction pour se connecter au serveur IRC
local function connect_to_irc()
    log("Tentative de connexion à " .. server .. ":" .. port)
    local client = luasocket.tcp()
    client:settimeout(10)
    local success, err = client:connect(server, port)
    if not success then
        log("Erreur de connexion: " .. tostring(err))
        client:close()
        return nil
    end
    log("Connecté avec succès!")
    return client
end

local function run_bot()
    while true do
        local client = connect_to_irc()
        if not client then
            log("Reconnexion dans " .. reconnect_delay .. "s...")
            luasocket.sleep(reconnect_delay)
        end

        local irc = IRCe.new()
        irc:load_module(mod_base)
        irc:load_module(mod_message)
        irc:load_module(mod_channel)

        irc:set_send_func(function(_, message)
            log(">> " .. message)
            return client:send(message)
        end)

        -- Callback pour les messages PRIVMSG
        irc:set_callback("PRIVMSG", function(_, sender, origin, msg)
            log(string.format("<%s> %s", sender[1], msg))

            -- Mettre à jour le canal actuel si le message vient d'un canal
            if origin:sub(1, 1) == "#" then
                current_channel = origin
            end

            -- Répondre à "salut lua_bot" en message privé
            if msg:lower():match("salut lua_bot") then
                log("Réponse privée: " .. response_message)
                irc:PRIVMSG(sender[1], response_message)
            end

            -- Répondre à "!salut" dans le canal actuel
            if msg:lower():match("^!salut") then
                log("Réponse dans " .. current_channel .. ": " .. response_message)
                irc:PRIVMSG(current_channel, response_message)
            end
        end)

        -- Callback pour les JOIN (mettre à jour le canal actuel)
        irc:set_callback("JOIN", function(_, sender, channel)
            if sender[1] == nickname then
                current_channel = channel
                log("Rejoint le canal: " .. current_channel)
            end
        end)

        irc:set_callback("PING", function(_, _, params)
            irc:PONG(params[1])
        end)

        irc:set_callback(IRCe.RAW, function(_, send, msg)
            if not send then log("<< " .. msg) end
        end)

        -- Connexion et join
        irc:NICK(nickname)
        irc:USER(nickname, "0", "*", nickname)
        irc:JOIN(default_channel)

        client:settimeout(80)
        while true do
            local line, err = client:receive()
            if not line then
                log("Déconnecté: " .. (err or "unknown"))
                client:close()
                break
            end
            irc:process(line)
        end
    end
end

log("Démarrage du bot...")
run_bot()

