local socket = require("socket")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")
local handlers = require("modules.irc.handlers")

-- Configuration
local irc_server = "irc.oftc.net"
local irc_port = 6667
local nickname = "lua_bot_" .. os.time() % 1000
local default_channel = "#monbot"
local reconnect_delay = 10
local connection_timeout = 60
local receive_timeout = 10
local current_channel = default_channel

-- Logger
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Connexion au serveur IRC
local function connect_to_irc()
    log("Connexion à " .. irc_server .. ":" .. irc_port)
    local client = socket.tcp()
    client:settimeout(connection_timeout)
    local success, err = client:connect(irc_server, irc_port)
    if not success then
        log("Erreur de connexion: " .. tostring(err))
        client:close()
        return nil
    end
    log("Connecté avec succès!")
    client:settimeout(receive_timeout)
    return client
end

-- Fonction principale du bot
local function run()
    while true do
        local irc_client = connect_to_irc()
        if not irc_client then
            log("Réessai dans " .. reconnect_delay .. " secondes...")
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
                if origin:sub(1, 1) == "#" then
                    current_channel = origin
                end

                if msg:lower() == "!salut" then
                    irc:PRIVMSG(current_channel, "Salut, je suis un bot Lua!")
                elseif msg:lower() == "!ping" then
                    irc:PRIVMSG(current_channel, "Pong!")
                elseif msg:lower() == "!create" then
                    handlers.start_character_creation(irc, sender[1], current_channel)
                elseif msg:lower() == "!recap" then
                    handlers.show_character_recap(irc, sender[1], current_channel)
                elseif msg:lower() == "!help" then
                    handlers.show_help(irc, sender[1], current_channel)
                elseif handlers.handle_character_creation(irc, sender[1], current_channel, msg) then
                    -- Géré par le handler
                end
            end)

            irc:set_callback("PING", function(_, _, params)
                irc:PONG(params[1])
                log("PONG envoyé.")
            end)

            irc:set_callback("ERROR", function(_, err)
                log("Erreur IRC: " .. tostring(err))
            end)

            irc:NICK(nickname)
            irc:USER(nickname, "0", "*", ":Lua Bot")
            irc:JOIN(default_channel)
            log("Bot prêt sur " .. default_channel)

            -- Boucle de réception
            local last_ping_time = socket.gettime()
            while true do
                local line, err = irc_client:receive()
                if not line then
                    if err ~= "timeout" then
                        log("Déconnecté: " .. (err or "unknown"))
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
                socket.sleep(0.1)
            end
        end
    end
end

return {
    run = run,
}

