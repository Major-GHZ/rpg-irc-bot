local bot = require("bot")
local conf = require("config")

local client = bot.IRCClient.new(bot)
client:connect(conf.get("server"), conf.get("port"))

copas.loop()

