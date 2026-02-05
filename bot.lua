local socket = require("socket")
local copas = require("copas")
local re = require("rex_pcre2")
local pl = require("pl")
local logging = require("logging")
local conf = require("config")

local bot = {}  -- Module principal du bot

-- Structure pour stocker un message IRC
local Message = {}
Message.__index = Message

function Message.new(tags, src, user, host, cmd, args, trailing, line, time)
    return setmetatable({
        tags = tags or {},
        src = src,
        user = user,
        host = host,
        cmd = cmd,
        args = args or {},
        trailing = trailing,
        line = line,
        time = time or os.time()
    }, Message)
end

-- Structure pour stocker un utilisateur IRC
local User = {}
User.__index = User

function User.new(nick, userhost, modes, joined)
    return setmetatable({
        nick = nick,
        userhost = userhost,
        modes = modes or {},
        joined = joined or os.time()
    }, User)
end

-- Classe IRCClient
local IRCClient = {}
IRCClient.__index = IRCClient

function IRCClient.new(bot)
    return setmetatable({
        _bot = bot,
        _writer = nil,
        _nick = conf.get("botnick"),
        _bytes_sent = 0,
        _bytes_received = 0,
        _caps = {},
        _server = nil,
        _messages_sent = 0,
        _writeq = {},
        _flushq_task = nil,
        _prefixmodes = {},
        _maxmodes = 3,
        _modetypes = {},
        _users = {},
        quitting = false,
        MESSAGE_RE = re.compile([=[^(?:@(\S*) )?(?::([^ !]*)(?:!([^ @]*)(?:@([^ ]*))?)?\s+)?(\S+)\s*((?:[^:]\S*(?:\s+|$))*)(?::(.*))?]=])
    }, IRCClient)
end

-- Parse un message IRC
function IRCClient.parse_message(line)
    local match = IRCClient.MESSAGE_RE:match(line)
    if not match then
        return nil
    end
    local rawtags, src, user, host, cmd, argstr, trailing = match[1], match[2], match[3], match[4], match[5], match[6], match[7]

    local tags = {}
    if rawtags and rawtags ~= "" then
        for pairstr in rawtags:gmatch("[^;]+") do
            local pair = pairstr:match("([^=]*)=(.*)")
            if pair then
                local key, value = pair[1], pair[2]
                value = value:gsub("\\(.)", function(m)
                    local c = m:sub(2, 2)
                    if c == ":" then return ";" end
                    if c == "s" then return " " end
                    if c == "r" then return "\r" end
                    if c == "n" then return "\n" end
                    return c
                end)
                tags[key] = value
            else
                tags[pairstr] = nil
            end
        end
    end

    local args = {}
    if argstr and argstr ~= "" then
        for arg in argstr:gmatch("%S+") do
            table.insert(args, arg)
        end
    end

    if trailing then
        table.insert(args, trailing)
    end

    if cmd:match("^%d+$") then
        table.remove(args, 1)
    end

    local msgtime = os.time()
    if tags.time then
        msgtime = os.time({
            year = tonumber(tags.time:sub(1, 4)),
            month = tonumber(tags.time:sub(6, 7)),
            day = tonumber(tags.time:sub(9, 10)),
            hour = tonumber(tags.time:sub(12, 13)),
            min = tonumber(tags.time:sub(15, 16)),
            sec = tonumber(tags.time:sub(18, 19))
        })
    end

    return Message.new(tags, src, user, host, cmd, args, trailing, line, msgtime)
end

-- Connexion au serveur IRC
function IRCClient:connect(addr, port)
    copas.addthread(function()
        local client = socket.tcp()
        client:settimeout(0)
        local ok, err = client:connect(addr, port)
        if not ok then
            logging.error("Erreur de connexion: " .. err)
            return
        end
        self._writer = client
        self._server = addr
        self._connected = true
        self._messages_sent = 0
        self._writeq = {}
        self._flushq_task = nil
        self._prefixmodes = {}
        self._maxmodes = 3
        self._modetypes = {}
        self._users = {}
        self._caps = {}

        self:sendnow("CAP REQ :multi-prefix userhost-in-names")
        self:sendnow("CAP END")
        if os.getenv("BOTPASS") then
            self:sendnow("PASS " .. os.getenv("BOTPASS"))
        end
        self:sendnow("NICK " .. conf.get("botnick"))
        self:sendnow("USER " .. conf.get("botuser") .. " 0 * :" .. conf.get("botrlnm"))

        self._bot:on_connect(self)

        while true do
            local line, err = client:receive("*l")
            if not line then
                if self._flushq_task then
                    copas.cancel(self._flushq_task)
                end
                self._bot:on_disconnect()
                client:close()
                break
            end
            self._bytes_received = self._bytes_received + #line
            local loglevel = line:match("^PING ") and 5 or logging.DEBUG
            logging.log(loglevel, "<- " .. line)
            local msg = IRCClient.parse_message(line)
            if msg then
                self:dispatch(msg)
            end
        end
    end)
end

-- Envoi d'un message (avec throttle)
function IRCClient:send(s, loglevel)
    loglevel = loglevel or logging.DEBUG
    assert(self._writer, "Pas de connexion active")
    local b = s .. "\r\n"

    if not conf.get("throttle") then
        logging.log(loglevel, "-> " .. s)
        self._writer:send(b)
        self._bytes_sent = self._bytes_sent + #b
        return
    end

    if self._messages_sent < conf.get("throttle_rate") then
        logging.log(loglevel, "(" .. self._messages_sent .. ")-> " .. s)
        self._writer:send(b)
        self._messages_sent = self._messages_sent + 1
        self._bytes_sent = self._bytes_sent + #b
    else
        table.insert(self._writeq, b)
    end

    if not self._flushq_task then
        self._flushq_task = copas.addthread(function()
            self:flushq_task()
        end)
    end
end

-- Envoi immédiat (ignore le throttle)
function IRCClient:sendnow(s, loglevel)
    loglevel = loglevel or logging.DEBUG
    assert(self._writer, "Pas de connexion active")
    logging.log(loglevel, "=> " .. s)
    local b = s .. "\r\n"
    self._writer:send(b)
    self._messages_sent = self._messages_sent + 1
    self._bytes_sent = self._bytes_sent + #b
    if conf.get("throttle") and not self._flushq_task then
        self._flushq_task = copas.addthread(function()
            self:flushq_task()
        end)
    end
end

-- Tâche de flush de la file d'attente
function IRCClient:flushq_task()
    copas.sleep(conf.get("throttle_period"))
    self._messages_sent = math.max(0, self._messages_sent - conf.get("throttle_rate"))
    while #self._writeq > 0 do
        while #self._writeq > 0 and self._messages_sent < conf.get("throttle_rate") do
            local msg = table.remove(self._writeq, 1)
            logging.debug("(" .. self._messages_sent .. ")~> " .. msg:gsub("\r\n", ""))
            self._writer:send(msg)
            self._messages_sent = self._messages_sent + 1
            self._bytes_sent = self._bytes_sent + #msg
        end
        if #self._writeq > 0 then
            copas.sleep(conf.get("throttle_period"))
            self._messages_sent = math.max(0, self._messages_sent - conf.get("throttle_rate"))
        end
    end
    self._flushq_task = nil
end

-- Dispatch des commandes IRC
function IRCClient:dispatch(msg)
    local handler = self["handle_" .. msg.cmd:lower()]
    if handler then
        handler(self, msg)
    end
end

-- Handlers pour les commandes IRC
function IRCClient:handle_ping(msg)
    self:sendnow("PONG :" .. msg.trailing, 5)
end

-- Ajoute un utilisateur
function IRCClient:add_user(nick, userhost, modes, joined)
    self._users[nick] = User.new(nick, userhost, modes, joined)
end

-- Supprime un utilisateur
function IRCClient:remove_user(nick)
    local user = self._users[nick]
    self._users[nick] = nil
    if next(self._users) == nil and not self:bot_has_ops() then
        self:sendnow("PART " .. conf.get("botchan") .. " :Acquiring ops")
        self:sendnow("JOIN " .. conf.get("botchan"))
    end
    return user
end

-- Vérifie si le bot a les ops
function IRCClient:bot_has_ops()
    return self._users[self._nick] and self._users[self._nick].modes.o
end

-- Envoi d'un message au canal
function IRCClient:chanmsg(text)
    for line in text:gmatch("[^\n]+") do
        self:send("PRIVMSG " .. conf.get("botchan") .. " :" .. line)
    end
end

-- Quitte le serveur
function IRCClient:quit(text)
    self.quitting = true
    if text then
        self:sendnow("QUIT :" .. text)
    else
        self:sendnow("QUIT")
    end
end

-- Retourne le nom du serveur
function IRCClient:servername()
    return self._server or "<disconnected>"
end

-- Retourne le nombre d'octets envoyés
function IRCClient:bytes_sent()
    return self._bytes_sent
end

-- Retourne le nombre d'octets reçus
function IRCClient:bytes_received()
    return self._bytes_received
end

-- Retourne la taille de la file d'attente
function IRCClient:writeq_len()
    local len = 0
    for _, b in ipairs(self._writeq) do
        len = len + #b
    end
    return len
end

-- Vide la file d'attente
function IRCClient:clear_writeq()
    self._writeq = {}
end

-- Interface du bot
bot.IRCClient = IRCClient

-- Fonctions de rappel pour le bot
function bot.on_connect(client)
    print("Connecté au serveur IRC.")
end

function bot.on_disconnect()
    print("Déconnecté du serveur IRC.")
end

function bot.on_nick_parted(user)
    print(user.nick .. " a quitté le canal.")
end

function bot.on_nick_kicked(user)
    print(user.nick .. " a été kické du canal.")
end

function bot.on_nick_changed(user, new_nick)
    print(user.nick .. " a changé de nick en " .. new_nick)
end

function bot.on_nick_quit(user)
    print(user.nick .. " a quitté IRC.")
end

function bot.on_private_message(user, message)
    print("Message privé de " .. user.nick .. ": " .. message)
end

function bot.on_channel_message(user, message)
    print("Message de " .. user.nick .. " dans " .. conf.get("botchan") .. ": " .. message)
end

return bot

