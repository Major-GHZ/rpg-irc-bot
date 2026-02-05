local irc = require("LuaIRC")
local ircbot = require("ircbot")

-- Configuration du bot
local config = {
    server = "irc.libera.chat",
    port = 6667,
    nick = "lua_bot",
    user = "lua_bot",
    realname = "Un bot Lua",
}

-- Création du bot
local bot = ircbot.new{
    server = config.server,
    port = config.port,
    nick = config.nick,
    user = config.user,
    realname = config.realname,
}

-- Gestion des événements
bot:hook("OnConnect", function(self, event)
    print("Connecté au serveur IRC !")
    self:join("#gamecodeur") -- Rejoindre le canal #test
end)

bot:hook("OnPrivmsg", function(self, event)
    local message = event.message:lower()
    if message:find("ping") then
        self:send("PRIVMSG " .. event.target .. " :pong")
    end
end)

-- Connexion au serveur
bot:connect()
print("Tentative de connexion au serveur IRC...")

