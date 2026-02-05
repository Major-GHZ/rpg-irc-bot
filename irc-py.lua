local socket = require("socket")
local copas = require("copas")
local re = require("rex_pcre2")
local pl = require("pl") -- penlight, pour textwrap et autres utilitaires
local log = require("logging") -- ou une bibliothèque de logging de ton choix

local IRCClient = {}
IRCClient.__index = IRCClient

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

-- Constructeur de IRCClient
function IRCClient.new(bot)
    local self = setmetatable({
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
    return self
end

-- Parse un message IRC
function IRCClient.parse_message(line)
    local match = IRCClient.MESSAGE_RE:match(line)
    if not match then
        return nil
    end
    local rawtags, src, user, host, cmd, argstr, trailing = match[1], match[2], match[3], match[4], match[5], match[6], match[7]

    -- Gestion des tags IRCv3
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

    -- Arguments avant le trailing
    local args = {}
    if argstr and argstr ~= "" then
        for arg in argstr:gmatch("%S+") do
            table.insert(args, arg)
        end
    end

    -- Ajout du trailing s'il existe
    if trailing then
        table.insert(args, trailing)
    end

    -- Suppression du target inutile pour les réponses numériques
    if cmd:match("^%d+$") then
        table.remove(args, 1)
    end

    -- Gestion du temps
    local msgtime = os.time()
    if tags.time then
        msgtime = os.time({year=tonumber(tags.time:sub(1,4)), month=tonumber(tags.time:sub(6,7)), day=tonumber(tags.time:sub(9,10)),
                           hour=tonumber(tags.time:sub(12,13)), min=tonumber(tags.time:sub(15,16)), sec=tonumber(tags.time:sub(18,19))})
    end

    return Message.new(tags, src, user, host, cmd, args, trailing, line, msgtime)
end

-- Connexion au serveur IRC
function IRCClient:connect(addr, port)
    copas.addthread(function()
        local client = socket.tcp()
        client:settimeout(0) -- Mode non-bloquant pour copas
        local ok, err = client:connect(addr, port)
        if not ok then
            log.error("Erreur de connexion: " .. err)
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

        -- Envoi des commandes initiales
        self:sendnow("CAP REQ :multi-prefix userhost-in-names")
        self:sendnow("CAP END")
        if os.getenv("BOTPASS") then
            self:sendnow("PASS " .. os.getenv("BOTPASS"))
        end
        self:sendnow("NICK " .. conf.get("botnick"))
        self:sendnow("USER " .. conf.get("botuser") .. " 0 * :" .. conf.get("botrlnm"))

        self._bot:connected(self)

        -- Boucle de lecture
        while true do
            local line, err = client:receive("*l")
            if not line then
                if self._flushq_task then
                    copas.cancel(self._flushq_task)
                end
                self._bot:disconnected()
                client:close()
                break
            end
            self._bytes_received = self._bytes_received + #line
            local loglevel = line:match("^PING ") and 5 or log.DEBUG
            log.log(loglevel, "<- " .. line)
            local msg = IRCClient.parse_message(line)
            if msg then
                self:dispatch(msg)
            end
        end
    end)
end

-- Envoi d'un message (avec throttle)
function IRCClient:send(s, loglevel)
    loglevel = loglevel or log.DEBUG
    assert(self._writer, "Pas de connexion active")
    local b = s .. "\r\n"

    if not conf.get("throttle") then
        log.log(loglevel, "-> " .. s)
        self._writer:send(b)
        self._bytes_sent = self._bytes_sent + #b
        return
    end

    if self._messages_sent < conf.get("throttle_rate") then
        log.log(loglevel, "(" .. self._messages_sent .. ")-> " .. s)
        self._writer:send(b)
        self._messages_sent = self._messages_sent + 1
        self._bytes_sent = self._bytes_sent + #b
    else
        table.insert(self._writeq, b)
    end

    -- Lancement de la tâche de flush si nécessaire
    if not self._flushq_task then
        self._flushq_task = copas.addthread(function()
            self:flushq_task()
        end)
    end
end

-- Envoi immédiat (ignore le throttle)
function IRCClient:sendnow(s, loglevel)
    loglevel = loglevel or log.DEBUG
    assert(self._writer, "Pas de connexion active")
    log.log(loglevel, "=> " .. s)
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
            log.debug("(" .. self._messages_sent .. ")~> " .. msg:gsub("\r\n", ""))
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

-- Handlers pour les commandes IRC (exemple pour PING)
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
    if #self._users == 1 and not self:bot_has_ops() then
        self:sendnow("PART " .. conf.get("botchan") .. " :Acquiring ops")
        self:sendnow("JOIN " .. conf.get("botchan"))
    end
    return user
end

-- Vérifie si l'utilisateur est OK
function IRCClient:user_is_ok(msg)
    -- Implémente la logique ici
    return true
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

-- Retourne le nombre d'octets dans la file d'attente
function IRCClient:writeq_bytes()
    return self:writeq_len()
end

-- Vide la file d'attente
function IRCClient:clear_writeq()
    self._writeq = {}
end

-- Exemple d'utilisation :
-- local bot = {} -- ton objet bot
-- local client = IRCClient.new(bot)
-- client:connect("irc.example.com", 6697)

return IRCClient

