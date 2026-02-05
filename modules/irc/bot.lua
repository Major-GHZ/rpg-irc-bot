-- Add Lua modules path
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Load configuration
local config = require("config")

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

-- IRC Configuration from config file
local irc_server = config.irc.server
local irc_port = config.irc.port
local nickname = config.irc.nickname .. os.time()
local default_channel = config.irc.default_channel
local reconnect_delay = config.irc.reconnect_delay
local connection_timeout = config.irc.connection_timeout
local receive_timeout = config.irc.receive_timeout
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

-- Show character statistics
local function show_character_stats(irc, sender_nick, channel)
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
        irc:PRIVMSG(channel, sender_nick .. ", use !stats to see your character information at any time.")
        xml.saveCharacter(character)
        characters[sender_nick] = character
        character_creation_state[sender_nick] = nil
    end

    return true
end

-- Start character creation
local function start_character_creation(irc, sender_nick, channel)
    character_creation_state[sender_nick] = {
        step = 1,
        character = {}
    }
    
    -- Display complete help for character creation
    irc:PRIVMSG(channel, "===== CHARACTER CREATION =====")
    irc:PRIVMSG(channel, sender_nick .. ", you will create a character with !createplayer.")
    irc:PRIVMSG(channel, "Characters have different statistics than monsters!")
    irc:PRIVMSG(channel, "Use !createmonster to create enemies.")
    irc:PRIVMSG(channel, "")
    irc:PRIVMSG(channel, "STEP 1/7: Character name")
    irc:PRIVMSG(channel, sender_nick .. ", enter your character's name:")
    irc:PRIVMSG(channel, "Example: Gandalf, Aragorn, Legolas")
end

-- Function to list all characters


-- Function to handle dice rolls
local function handle_roll_command(irc, sender_nick, channel, msg)
    local num_dice = tonumber(msg:match("^!roll (%d+)")) or 1
    if num_dice < 1 then
        num_dice = 1
    elseif num_dice > config.game.max_dice_roll then
        num_dice = config.game.max_dice_roll
    end
    
    local results, total = Dice.roll_dice(num_dice)
    local response = sender_nick .. ", you rolled " .. num_dice .. " dice: " .. Dice.format_dice_roll(results, total)
    irc:PRIVMSG(channel, response)
end



-- Function to handle monster creation
local function handle_create_monster_command(irc, sender_nick, channel, msg)
    local monster_name, monster_class_name, level = msg:match("^!createmonster (%S+) (%S+) (%d+)")
    
    -- If no parameters are provided, display complete and distinct help
    if not monster_name or not monster_class_name then
        irc:PRIVMSG(channel, "===== HEROIC FANTASY MONSTER CREATION =====")
        irc:PRIVMSG(channel, sender_nick .. ", to create a MONSTER, use:")
        irc:PRIVMSG(channel, "!createmonster <name> <class> <level>")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "AVAILABLE MONSTER CLASSES:")
        
        -- Display classes with their descriptions
        local classes = MonsterCreation.getAllMonsterClassesWithDetails()
        for _, class in ipairs(classes) do
            irc:PRIVMSG(channel, "• " .. class.display_name .. " : " .. class.description)
        end
        
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "EXAMPLES:")
        irc:PRIVMSG(channel, "!createmonster BlackDragon phenix 10")
        irc:PRIVMSG(channel, "!createmonster AncientVampire vampire 15")
        irc:PRIVMSG(channel, "!createmonster GiantKraken kraken 20")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "TIP: Monsters have different statistics than characters!")
        irc:PRIVMSG(channel, "They use Health/Damage/Armor instead of Energy.")
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
        irc:PRIVMSG(channel, "===== MONSTER CREATED SUCCESSFULLY =====")
        irc:PRIVMSG(channel, sender_nick .. ", your monster is ready for combat!")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "MONSTER INFORMATION:")
        irc:PRIVMSG(channel, "Name: " .. monster.name .. " (" .. monster.class .. ")")
        irc:PRIVMSG(channel, "Level: " .. monster.level)
        irc:PRIVMSG(channel, "Health: " .. monster.health .. "/" .. monster.health_max)
        irc:PRIVMSG(channel, "Damage: " .. monster.damage)
        irc:PRIVMSG(channel, "Armor: " .. monster.armor)
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "ATTRIBUTES:")
        irc:PRIVMSG(channel, "Intelligence: " .. monster.attributes.intelligence)
        irc:PRIVMSG(channel, "Strength: " .. monster.attributes.strength)
        irc:PRIVMSG(channel, "Dexterity: " .. monster.attributes.dexterity)
        irc:PRIVMSG(channel, "Endurance: " .. monster.attributes.endurance)
        irc:PRIVMSG(channel, "Magic: " .. monster.attributes.magic)
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "SPECIAL SPELLS:")
        irc:PRIVMSG(channel, table.concat(monster.spells, ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "The monster has been saved successfully!")
    else
        irc:PRIVMSG(channel, sender_nick .. ", Error during save: " .. tostring(save_err))
        irc:PRIVMSG(channel, "The monster was created in memory but could not be saved.")
    end
end

-- Function to list all monsters
local function handle_list_monsters_command(irc, sender_nick, channel)
    local monsters, list_err = MonsterCreation.listMonsters()
    
    if list_err then
        irc:PRIVMSG(channel, sender_nick .. ", ✗ Error reading monsters: " .. list_err)
        return
    end
    
    if #monsters == 0 then
        irc:PRIVMSG(channel, sender_nick .. ", no monsters have been created yet.")
        return
    end
    
    local response = "List of created monsters (" .. #monsters .. ") : "
    
    for _, monster in ipairs(monsters) do
        response = response .. monster.name .. " (" .. monster.class .. ", Lvl. " .. monster.level .. "), "
    end
    
    -- Remove the last comma and space
    irc:PRIVMSG(channel, response:sub(1, -3))
end

-- IRC command handling
local function handle_irc_command(irc, sender_nick, channel, msg)
    if msg:lower():match("^!createplayer") then
        start_character_creation(irc, sender_nick, channel)
    elseif msg:lower():match("^!stats") then
        show_character_stats(irc, sender_nick, channel)
    elseif msg:lower():match("^!listplayer") then
        -- List all saved characters
        local characters = xml.getAllCharactersFromXML()
        
        if next(characters) == nil then
            irc:PRIVMSG(channel, sender_nick .. ", no characters found in saved files.")
            irc:PRIVMSG(channel, "Use !createplayer to create a new character.")
        else
            irc:PRIVMSG(channel, sender_nick .. ", here is the list of saved characters (" .. #characters .. "):")
            
            for name, char in pairs(characters) do
                irc:PRIVMSG(channel, "• " .. name .. " (" .. char.class .. ", Level " .. char.level .. ") - Energy: " .. char.energy .. "/" .. char.energieMax .. ")")
            end
            
            irc:PRIVMSG(channel, "Use !getplayer <name> to load a specific character.")
        end
    elseif msg:lower():match("^!getplayer") then
        -- Extract the character name to load
        local player_name = msg:match("^!getplayer (%S+)")
        if not player_name then
            irc:PRIVMSG(channel, sender_nick .. ", usage: !getplayer <name>")
            irc:PRIVMSG(channel, "Example: !getplayer Gandalf")
            return
        end
        
        -- Load the specific character (case insensitive)
        local character = xml.getCharacterFromXML(player_name)
        
        -- If not found, try with first letter capitalized
        if not character then
            local capitalized_name = player_name:sub(1, 1):upper() .. player_name:sub(2)
            character = xml.getCharacterFromXML(capitalized_name)
        end
        
        -- If still not found, try in lowercase
        if not character then
            local lowercase_name = player_name:lower()
            character = xml.getCharacterFromXML(lowercase_name)
        end
        
        if character then
            -- Add the character to the list of active characters
            characters[sender_nick] = character
            irc:PRIVMSG(channel, sender_nick .. ", the character '" .. character.name .. "' has been loaded successfully!")
            irc:PRIVMSG(channel, "Use !stats to see its information.")
        else
            irc:PRIVMSG(channel, sender_nick .. ", the character '" .. player_name .. "' was not found.")
            irc:PRIVMSG(channel, "Use !listplayer to see available characters.")
        end
    elseif msg:lower():match("^!roll") then
        handle_roll_command(irc, sender_nick, channel, msg)
    elseif msg:lower():match("^!createmonster") then
        handle_create_monster_command(irc, sender_nick, channel, msg)
    elseif msg:lower():match("^!listmonsters") then
        handle_list_monsters_command(irc, sender_nick, channel)
    elseif msg:lower():match("^!ping") then
        irc:PRIVMSG(channel, "Pong!")
    elseif msg:lower():match("^!hello") then
        irc:PRIVMSG(channel, "Hello, " .. sender_nick .. "!")
    elseif msg:lower():match("^!help") then
        irc:PRIVMSG(channel, "===== RPG BOT HELP =====")
        irc:PRIVMSG(channel, sender_nick .. ", here are the available commands:")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "CHARACTER CREATION (for players):")
        irc:PRIVMSG(channel, "!createplayer - Start creating a player character")
        irc:PRIVMSG(channel, "Available classes: " .. table.concat(CharacterClasses.getAvailableClasses(), ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "MONSTER CREATION (for enemies):")
        irc:PRIVMSG(channel, "!createmonster <name> <class> <level> - Create a heroic fantasy monster")
        irc:PRIVMSG(channel, "Available classes: " .. table.concat(MonsterCreation.getAvailableMonsterClasses(), ", "))
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "OTHER COMMANDS:")
        irc:PRIVMSG(channel, "!stats - Show your character statistics")

        irc:PRIVMSG(channel, "!listmonsters - List all created monsters")
        irc:PRIVMSG(channel, "!listplayer - List all saved characters")
        irc:PRIVMSG(channel, "!getplayer <name> - Load a specific character")
        irc:PRIVMSG(channel, "!roll <number> - Roll dice (ex: !roll 2)")
        irc:PRIVMSG(channel, "!ping - Test connection to the bot")
        irc:PRIVMSG(channel, "!hello - Say hello to the bot")
        irc:PRIVMSG(channel, "!help - Show this help")
        irc:PRIVMSG(channel, "")
        irc:PRIVMSG(channel, "DIFFERENCES BETWEEN CHARACTERS AND MONSTERS:")
        irc:PRIVMSG(channel, "• Characters: Use Energy, have player classes")
        irc:PRIVMSG(channel, "• Monsters: Use Health/Damage/Armor, have creature classes")
        irc:PRIVMSG(channel, "• Use !createplayer for heroes, !createmonster for enemies!")
    elseif character_creation_state[sender_nick] then
        -- Check if the current command should cancel character creation
        if msg:lower():match("^!createmonster") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", character creation cancelled.")
            handle_create_monster_command(irc, sender_nick, channel, msg)
        elseif msg:lower():match("^!help") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", character creation cancelled.")
            irc:PRIVMSG(channel, "===== RPG BOT HELP =====")
            irc:PRIVMSG(channel, sender_nick .. ", here are the available commands:")
            irc:PRIVMSG(channel, "")
            irc:PRIVMSG(channel, "CHARACTER CREATION (for players):")
            irc:PRIVMSG(channel, "!createplayer - Start creating a player character")
            irc:PRIVMSG(channel, "Available classes: " .. table.concat(CharacterClasses.getAvailableClasses(), ", "))
            irc:PRIVMSG(channel, "")
            irc:PRIVMSG(channel, "MONSTER CREATION (for enemies):")
            irc:PRIVMSG(channel, "!createmonster <name> <class> <level> - Create a heroic fantasy monster")
            irc:PRIVMSG(channel, "Available classes: " .. table.concat(MonsterCreation.getAvailableMonsterClasses(), ", "))
        elseif msg:lower():match("^!listmonsters") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", character creation cancelled.")
            handle_list_monsters_command(irc, sender_nick, channel)
        elseif msg:lower():match("^!roll") then
            character_creation_state[sender_nick] = nil
            irc:PRIVMSG(channel, sender_nick .. ", character creation cancelled.")
            handle_roll_command(irc, sender_nick, channel, msg)
        else
            handle_character_creation(irc, sender_nick, channel, msg)
        end
    end
end

-- Launch the IRC bot
local function run_irc_bot()
    while true do
        local irc_client = connect_to_irc()
        if not irc_client then
            log("Connection failed. Retrying in " .. reconnect_delay .. " seconds...")
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
                log("IRC error: " .. tostring(err))
            end)

            irc:NICK(nickname)
            irc:USER(nickname, "0", "*", ":Lua Bot")
            irc:JOIN(default_channel)
            log("IRC bot ready and connected to " .. default_channel)

            local last_ping_time = socket.gettime()
            while true do
                local line, err = irc_client:receive()
                if not line then
                    if err ~= "timeout" then
                        log("Disconnected from IRC server: " .. (err or "unknown"))
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
