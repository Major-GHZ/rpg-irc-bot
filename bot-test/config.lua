local conf = {}

-- Configuration de base du bot
conf.botnick = "lua_bot"          -- Nom du bot sur IRC
conf.botuser = "lua_bot_user"    -- Nom d'utilisateur du bot
conf.botrlnm = "Lua IRC Bot"      -- Nom réel du bot (affiché dans /whois)

-- Configuration du canal
conf.botchan = "#gamecodeur"            -- Canal par défaut où le bot se connecte
conf.botmodes = "+B"              -- Modes du bot (exemple : +B pour bot)

-- Configuration du serveur IRC
conf.server = "irc.libera.chat"   -- Adresse du serveur IRC
conf.port = 6697                  -- Port du serveur IRC (6697 pour SSL)

-- Configuration de la connexion
conf.localaddr = nil              -- Adresse locale pour la connexion (nil pour automatique)

-- Configuration du throttle (limitation du débit)
conf.throttle = true              -- Activer la limitation du débit
conf.throttle_rate = 5            -- Nombre de messages autorisés par période
conf.throttle_period = 1          -- Période de limitation en secondes

-- Configuration des messages
conf.message_wrap_len = 400       -- Longueur maximale d'une ligne de message

-- Configuration des bans
conf.doban = true                 -- Activer les bans automatiques
conf.bannable_time = 300          -- Temps en secondes avant qu'un utilisateur ne soit considéré comme "ok"
conf.okurls = {                   -- Liste des URL autorisées (pour éviter les bans)
    "example.com",
    "trusted-site.org",
}

-- Configuration des commandes spéciales
conf.botopcmd = nil               -- Commande pour obtenir les ops (exemple : "MODE #test +o %botnick%")
conf.botghostcmd = nil           -- Commande pour récupérer son nick (exemple : "GHOST %botnick% password")

-- Fonction pour récupérer une valeur de configuration
function conf.get(key)
    return conf[key]
end

-- Fonction pour vérifier si une clé existe
function conf.has(key)
    return conf[key] ~= nil
end

return conf

