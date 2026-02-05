local socket = require("socket")
local json = require("dkjson")

-- Configuration du client
local game_host = "127.0.0.1"
local game_port = 12345

-- Connexion au serveur de jeu
local game_client = socket.tcp()
game_client:settimeout(60)  -- Timeout augmenté à 60 secondes
local success, err = game_client:connect(game_host, game_port)
if not success then
    print("Erreur de connexion au serveur de jeu:", err)
    os.exit(1)
end

print("Connecté au serveur de jeu.")

-- Boucle d'envoi/réception
while true do
    -- Exemple : Envoyer une commande au serveur de jeu
    game_client:send(json.encode({ type = "command", text = "!attack" }) .. "\n")

    -- Réception de la réponse
    local line, err = game_client:receive()
    if not line then
        print("Erreur ou déconnexion:", err)
        break
    end
    print("Réponse du serveur:", line)

    socket.sleep(1)
end

game_client:close()
print("Client fermé.")

