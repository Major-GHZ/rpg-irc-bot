-- Add Lua modules path
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Load game modules
local Character = require("character")
local CharacterClasses = require("character_classes")
local Dice = require("dice")
local MonsterCreation = require("monster_creation")
local xml = require("character_xml")

-- Load IRC modules
local socket = require("socket")
local IRCe = require("irce")
local mod_base = require("irce.modules.base")
local mod_message = require("irce.modules.message")
local mod_channel = require("irce.modules.channel")

-- State for character creation via IRC
local character_creation_state = {}
local characters = {}

-- Function to reload characters from XML files
local function retrieve_characters()
    characters = {}
    local chars = xml.getAllCharactersFromXML()
    for username, char in pairs(chars) do
        characters[username] = char
    end
    return #chars
end

-- IRC Configuration
local irc_server = "irc.oftc.net"
local irc_port = 6667
local nickname = "lua_bot_" .. os.time()
local default_channel = "#monbot"
local reconnect_delay = 10
local connection_timeout = 30
local receive_timeout = 5
local current_channel = default_channel

-- Logging function
local function log(message)
    print(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
end

-- Connect to IRC server
local function connect_to_irc()
    log("Attempting to connect to " .. irc_server .. ":" .. irc_port)
    local client = socket.tcp()
    client:settimeout(connection_timeout)
    local success, err = client:connect(irc_server, irc_port)
    if not success then
        log("IRC connection error: " .. tostring(err))
        client:close()
        return nil
    end
    log("Successfully connected to IRC server!")
    client:settimeout(receive_timeout)
    return client
end

-- Show character recap
local function show_character_recap(irc, sender_nick, channel)
    if characters[sender_nick] then
        local character = characters[sender_nick]
        local recap = string.format(
            "%s, character recap: %s (%s, Level %d). Attributes: Int=%d, Str=%d, Dex=%d, End=%d, Mag=%d. Spells: %s. Energy: %d/%d",
            sender_nick,
            character.name,
            character.class,
            character.level,
            character.attributes.intelligence,
            character.attributes.strength,
            character.attributes.dexterity,
            character.attributes.endurance,
            character.attributes.magic,
            table.concat(character.spells, ", "),
            character.energy,
            character.energieMax
        )
        irc:PRIVMSG(channel, recap)
    else
        irc:PRIVMSG(channel, sender_nick .. ", you haven't created a character yet.")
    end
end

-- Function to ask for a specific attribute
local function ask_for_attribute(irc, sender_nick, channel, attribute, state)
    state.step = state.step + 1
    irc:PRIVMSG(channel, sender_nick .. ", enter value for " .. attribute .. " (max " .. state.points_restants .. ", remaining points: " .. state.points_restants .. ") :")
end

-- Handle character creation
local function handle_character_creation(irc, sender_nick, channel, msg)
    if not character_creation_state[sender_nick] then
        return false
    end

    local state = character_creation_state[sender_nick]

    if state.step == 1 then
        state.character.name = msg
        irc:PRIVMSG(channel, sender_nick .. ", choose a class (" .. table.concat(CharacterClasses.getAvailableClasses(), "/") .. ") :")
        state.step = 2
    elseif state.step == 2 then
        state.character.class = msg:lower()
        local character_class = CharacterClasses.getClass(state.character.class)
        if not character_class then
            irc:PRIVMSG(channel, sender_nick .. ", invalid class. Available classes: " .. table.concat(CharacterClasses.getAvailableClasses(), ", ") .. ". Please try again:")
            return true
        end
        state.character.attributes = character_class.base_attributes
        state.points_restants = 30
        irc:PRIVMSG(channel, sender_nick .. ", you have 30 points to distribute among your attributes.")
        ask_for_attribute(irc, sender_nick, channel, "intelligence", state)
    elseif state.step == 3 then  -- Intelligence
        local int = tonumber(msg)
        if not int or int < 0 or int > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", invalid value for intelligence (max " .. state.points_restants .. "). Please try again:")
            return true
        end
        state.character.attributes.intelligence = int
        state.points_restants = state.points_restants - int
        ask_for_attribute(irc, sender_nick, channel, "strength", state)
    elseif state.step == 4 then  -- Strength
        local str = tonumber(msg)
        if not str or str < 0 or str > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", invalid value for strength (max " .. state.points_restants .. "). Please try again:")
            return true
        end
        state.character.attributes.strength = str
        state.points_restants = state.points_restants - str
        ask_for_attribute(irc, sender_nick, channel, "dexterity", state)
    elseif state.step == 5 then  -- Dexterity
        local dex = tonumber(msg)
        if not dex or dex < 0 or dex > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", invalid value for dexterity (max " .. state.points_restants .. "). Please try again:")
            return true
        end
        state.character.attributes.dexterity = dex
        state.points_restants = state.points_restants - dex
        ask_for_attribute(irc, sender_nick, channel, "endurance", state)
    elseif state.step == 6 then  -- Endurance
        local end_ = tonumber(msg)
        if not end_ or end_ < 0 or end_ > state.points_restants then
            irc:PRIVMSG(channel, sender_nick .. ", invalid value for endurance (max " .. state.points_restants .. "). Please try again:")
            return true
        end
        state.character.attributes.endurance = end_
        state.character.attributes.magic = state.points_restants - end_
        irc:PRIVMSG(channel, sender_nick .. ", you have " .. (state.points_restants - end_) .. " points left for magic.")
        irc:PRIVMSG(channel, sender_nick .. ", enter level (1-10) :")
        state.step = 7
    elseif state.step == 7 then  -- Level
        local level = tonumber(msg) or 1
        level = math.max(1, math.min(10, level))
        state.character.level = level

        local character = Character:createCharacterWithAttributes(
            state.character.name,
            state.character.class,
            state.character.level,
            state.character.attributes
        )

        local recap = string.format(
            "%s, your character has been created: %s (%s, Level %d). Attributes: Int=%d, Str=%d, Dex=%d, End=%d, Mag=%d. Spells: %s",
            sender_nick,
            character.name,
            character.class,
            character.level,
            character.attributes.intelligence,
            character.attributes.strength,
            character.attributes.dexterity,
            character.attributes.endurance,
            character.attributes.magic,
            table.concat(character.spells, ", ")
        )
        irc:PRIVMSG(channel, recap)
        xml.sauvegarder_personnage(character)
        characters[sender_nick] = character
        character_creation_state[sender_nick] = nil
    end

    return true
end

-- Démarre la création de personnage
local function start_character_creation(irc, sender_nick, channel)
    character_creation_state[sender_nick] = {
        step = 1,
        character = {}
    }
    
    -- Afficher une aide complète pour la création de personnages
    irc:PRIVMSG(channel, "===== CHARACTER CREATION =====")
    irc:PRIVMSG(channel, sender_nick .. ", you will create a character with !createjoueur.")
    irc:PRIVMSG(channel, "Characters have different statistics than monsters!")
    irc:PRIVMSG(channel, "Use !createmonster to create enemies.")
    irc:PRIVMSG(channel, "")
    irc:PRIVMSG(channel, "ETAPE 1/7 : Nom du personnage")
    irc:PRIVMSG(channel, sender_nick .. ", entrez le nom de votre personnage :")
    irc:PRIVMSG(channel, "Exemple : Gandalf, Aragorn, Legolas")
end

-- Fonction pour lister tous les personnages


-- Fonction pour gérer les jets de dés
local function handle_roll_command(irc, sender_nick, channel, msg)
    local num_dice = tonumber(msg:match("^!roll (%d+)")) or 1
    if num_dice < 1 then
        num_dice = 1
    elseif num_dice > 10 then
        num_dice = 10
    end
    
    local results, total = Dice.roll_dice(num_dice)
    local response = sender_nick .. ", vous avez lancé " .. num_dice .. " dés : " .. Dice.format_dice_roll(results, total)
    irc:PRIVMSG(channel, response)
end



-- Fonction pour gérer la création de monstres
local function handle_create_monster_command(irc, sender_nick, channel, msg)
    local monster_name, monster_class_name, level = msg:match("^!createmonster (%S+) (%S+) (%d+)")
    
    -- Si aucun paramètre n'est fourni, afficher une aide complète et distincte
    if not monster_name or not monster_class_name then
        irc:PRIVMSG(channel, "===== CREATION DE MONSTRES D'HEROIC FANTASY =====")
        irc:PRIVMSG(channel, sender_nick .. ", pour créer un MONSTRE, utilisez :")
        irc:PRIVMSG(channel, "!createmonster <nom> <classe> <niveau>")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "CLASSES DE MONSTRES DISPONIBLES :")
        
        -- Afficher les classes avec leurs descriptions
        local classes = MonsterCreation.getAllMonsterClassesWithDetails()
        for _, class in ipairs(classes) do
            irc:PRIVMSG(channel, "• " .. class.display_name .. " : " .. class.description)
        end
        
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "EXEMPLES :")
        irc:PRIVMSG(channel, "!createmonster DragonNoir phenix 10")
        irc:PRIVMSG(channel, "!createmonster VampireAncien vampire 15")
        irc:PRIVMSG(channel, "!createmonster KrakenGéant kraken 20")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "CONSEIL : Les monstres ont des statistiques différentes des personnages !")
        irc:PRIVMSG(channel, "Ils utilisent Santé/Dégâts/Armure au lieu d'Énergie.")
        return
    end
    
    level = tonumber(level) or 1
    local monster, err = MonsterCreation.createMonster(monster_name, monster_class_name, level)
    if not monster then
        irc:PRIVMSG(channel, sender_nick .. ", ✗ " .. err)
        return
    end
    
    local success, save_err = MonsterCreation.saveMonster(monster)
    if success then
        irc:PRIVMSG(channel, "===== MONSTRE CREE AVEC SUCCES =====")
        irc:PRIVMSG(channel, sender_nick .. ", votre monstre est pret pour le combat !")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "INFORMATIONS DU MONSTRE :")
        irc:PRIVMSG(channel, "Nom : " .. monster.name .. " (" .. monster.class .. ")")
        irc:PRIVMSG(channel, "Niveau : " .. monster.level)
        irc:PRIVMSG(channel, "Sante : " .. monster.health .. "/" .. monster.health_max)
        irc:PRIVMSG(channel, "Degats : " .. monster.damage)
        irc:PRIVMSG(channel, "Armure : " .. monster.armor)
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "ATTRIBUTS :")
        irc:PRIVMSG(channel, "Intelligence : " .. monster.attributes.intelligence)
        irc:PRIVMSG(channel, "Force : " .. monster.attributes.strength)
        irc:PRIVMSG(channel, "Dexterite : " .. monster.attributes.dexterity)
        irc:PRIVMSG(channel, "Endurance : " .. monster.attributes.endurance)
        irc:PRIVMSG(channel, "Magie : " .. monster.attributes.magic)
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "SORTS SPECIAUX :")
        irc:PRIVMSG(channel, table.concat(monster.spells, ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "Le monstre a ete sauvegarde avec succes !")
    else
        irc:PRIVMSG(channel, sender_nick .. ", Erreur lors de la sauvegarde : " .. tostring(save_err))
        irc:PRIVMSG(channel, "Le monstre a ete cree en memoire mais n'a pas pu etre sauvegarde.")
    end
end

-- Fonction pour lister tous les monstres
local function handle_list_monsters_command(irc, sender_nick, channel)
    local monsters, list_err = MonsterCreation.listMonsters()
    
    if list_err then
        irc:PRIVMSG(channel, sender_nick .. ", ✗ Erreur lors de la lecture des monstres : " .. list_err)
        return
    end
    
    if #monsters == 0 then
        irc:PRIVMSG(channel, sender_nick .. ", aucun monstre n'a été créé pour le moment.")
        return
    end
    
    local response = "Liste des monstres créés (" .. #monsters .. ") : "
    
    for _, monster in ipairs(monsters) do
        response = response .. monster.name .. " (" .. monster.class .. ", Niv. " .. monster.level .. "), "
    end
    
    -- Supprimer la dernière virgule et espace
    irc:PRIVMSG(channel, response:sub(1, -3))
end

-- Gestion des commandes IRC
local function handle_irc_command(irc, sender_nick, channel, msg)
    if msg:lower():match("^!createjoueur") then
        start_character_creation(irc, sender_nick, channel)
    elseif msg:lower():match("^!recap") then
        show_character_recap(irc, sender_nick, channel)
    elseif msg:lower():match("^!listjoueur") then
        -- Lister tous les personnages sauvegardés
        local characters = xml.getAllCharactersFromXML()
        
        if next(characters) == nil then
            irc:PRIVMSG(channel, sender_nick .. ", aucun personnage n'a été trouvé dans les fichiers sauvegardés.")
            irc:PRIVMSG(channel, "Utilisez !createjoueur pour créer un nouveau personnage.")
        else
            irc:PRIVMSG(channel, sender_nick .. ", voici la liste des personnages sauvegardés (" .. #characters .. "):")
            
            for name, char in pairs(characters) do
                irc:PRIVMSG(channel, "• " .. name .. " (" .. char.class .. ", Niveau " .. char.level .. ") - Énergie: " .. char.energy .. "/" .. char.energieMax .. ")")
            end
            
            irc:PRIVMSG(channel, "Utilisez !getjoueur <nom> pour charger un personnage spécifique.")
        end
    elseif msg:lower():match("^!getjoueur") then
        -- Extraire le nom du personnage à charger
        local player_name = msg:match("^!getjoueur (%S+)")
        if not player_name then
            irc:PRIVMSG(channel, sender_nick .. ", utilisation : !getjoueur <nom>")
            irc:PRIVMSG(channel, "Exemple : !getjoueur Gandalf")
            return
        end
        
        -- Charger le personnage spécifique (insensible à la casse)
        local character = xml.getCharacterFromXML(player_name)
        
        -- Si pas trouvé, essayer avec la première lettre en majuscule
        if not character then
            local capitalized_name = player_name:sub(1, 1):upper() .. player_name:sub(2)
            character = xml.getCharacterFromXML(capitalized_name)
        end
        
        -- Si toujours pas trouvé, essayer en minuscules
        if not character then
            local lowercase_name = player_name:lower()
            character = xml.getCharacterFromXML(lowercase_name)
        end
        
        if character then
            -- Ajouter le personnage à la liste des personnages actifs
            characters[sender_nick] = character
            irc:PRIVMSG(channel, sender_nick .. ", le personnage '" .. character.name .. "' a été chargé avec succès !")
            irc:PRIVMSG(channel, "Utilisez !recap pour voir ses informations.")
        else
            irc:PRIVMSG(channel, sender_nick .. ", le personnage '" .. player_name .. "' n'a pas été trouvé.")
            irc:PRIVMSG(channel, "Utilisez !listjoueur pour voir les personnages disponibles.")
        end
    elseif msg:lower():match("^!roll") then
        handle_roll_command(irc, sender_nick, channel, msg)
    elseif msg:lower():match("^!createmonster") then
        handle_create_monster_command(irc, sender_nick, channel, msg)
    elseif msg:lower():match("^!listmonsters") then
        handle_list_monsters_command(irc, sender_nick, channel)
    elseif msg:lower():match("^!ping") then
        irc:PRIVMSG(channel, "Pong!")
    elseif msg:lower():match("^!salut") then
        irc:PRIVMSG(channel, "Salut, " .. sender_nick .. " !")
    elseif msg:lower():match("^!help") then
        irc:PRIVMSG(channel, "===== AIDE DU BOT RPG =====")
        irc:PRIVMSG(channel, sender_nick .. ", voici les commandes disponibles :")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "CREATION DE PERSONNAGES (pour les joueurs) :")
        irc:PRIVMSG(channel, "!createjoueur - Demarre la creation d'un personnage joueur")
        irc:PRIVMSG(channel, "Classes disponibles : " .. table.concat(CharacterClasses.getAvailableClasses(), ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "CREATION DE MONSTRES (pour les ennemis) :")
        irc:PRIVMSG(channel, "!createmonster <nom> <classe> <niveau> - Cree un monstre d'heroic fantasy")
        irc:PRIVMSG(channel, "Classes disponibles : " .. table.concat(MonsterCreation.getAvailableMonsterClasses(), ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "AUTRES COMMANDES :")
        irc:PRIVMSG(channel, "!recap - Affiche le recapitulatif de votre personnage")

        irc:PRIVMSG(channel, "!listmonsters - Liste tous les monstres crees")
        irc:PRIVMSG(channel, "!listjoueur - Liste tous les personnages sauvegardés")
        irc:PRIVMSG(channel, "!getjoueur <nom> - Charge un personnage spécifique")
        irc:PRIVMSG(channel, "!roll <nombre> - Lance des des (ex: !roll 2)")
        irc:PRIVMSG(channel, "!ping - Test la connexion au bot")
        irc:PRIVMSG(channel, "!salut - Dit bonjour au bot")
        irc:PRIVMSG(channel, "!help - Affiche cette aide")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "DIFFERENCES ENTRE PERSONNAGES ET MONSTRES :")
        irc:PRIVMSG(channel, "• Personnages : Utilisent Energie, ont des classes de joueurs")
        irc:PRIVMSG(channel, "• Monstres : Utilisent Sante/Degats/Armure, ont des classes de creatures")
        irc:PRIVMSG(channel, "• Utilisez !createjoueur pour les heros, !createmonster pour les ennemis !")
    elseif character_creation_state[sender_nick] then
        -- Vérifier si la commande actuelle devrait annuler la création de personnage
        if msg:lower():match("^!createmonster") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", création de personnage annulée.")
            handle_create_monster_command(irc, sender_nick, channel, msg)
        elseif msg:lower():match("^!help") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", creation de personnage annulee.")
            irc:PRIVMSG(channel, "===== AIDE DU BOT RPG =====")
            irc:PRIVMSG(channel, sender_nick .. ", voici les commandes disponibles :")
            irc:PRIVMSG(channel, "")
            irc:PRIVMSG(channel, "CREATION DE PERSONNAGES (pour les joueurs) :")
            irc:PRIVMSG(channel, "!createjoueur - Demarre la creation d'un personnage joueur")
            irc:PRIVMSG(channel, "Classes disponibles : " .. table.concat(CharacterClasses.getAvailableClasses(), ", "))
            irc:PRIVMSG(channel, "")
            irc:PRIVMSG(channel, "CREATION DE MONSTRES (pour les ennemis) :")
            irc:PRIVMSG(channel, "!createmonster <nom> <classe> <niveau> - Cree un monstre d'heroic fantasy")
            irc:PRIVMSG(channel, "Classes disponibles : " .. table.concat(MonsterCreation.getAvailableMonsterClasses(), ", "))
        elseif msg:lower():match("^!listmonsters") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", création de personnage annulée.")
            handle_list_monsters_command(irc, sender_nick, channel)
        elseif msg:lower():match("^!roll") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", création de personnage annulée.")
            handle_roll_command(irc, sender_nick, channel, msg)
        else
            handle_character_creation(irc, sender_nick, channel, msg)
        end
    end
end

-- Lancement du bot IRC
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

            irc:set_callback("PRIVMSG", function(_, sender, origin, msg)
                log(string.format("<%s> %s", sender[1], msg))
                if origin:sub(1, 1) == "#" then current_channel = origin end
                handle_irc_command(irc, sender[1], current_channel, msg)
            end)

            irc:set_callback("PING", function(_, _, params)
                irc:PONG(params[1])
                log("PONG envoyé en réponse à PING.")
            end)

            irc:set_callback("ERROR", function(_, err)
                log("Erreur IRC: " .. tostring(err))
            end)

            irc:NICK(nickname)
            irc:USER(nickname, "0", "*", ":Lua Bot")
            irc:JOIN(default_channel)
            log("Bot IRC prêt et connecté à " .. default_channel)

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

-- Point d'entrée
return {
    run_irc_bot = run_irc_bot
}
