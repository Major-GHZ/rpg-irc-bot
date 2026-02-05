-- IRC Bot Configuration
-- This file contains all configurable parameters for the RPG IRC Bot

local config = {}

-- IRC Server Configuration
config.irc = {
    server = "irc.oftc.net",           -- IRC server address
    port = 6667,                       -- IRC server port
    nickname = "RPG_Bot_",            -- Bot nickname prefix
    default_channel = "#rpg-game",    -- Default channel to join
    reconnect_delay = 10,             -- Delay in seconds between reconnection attempts
    connection_timeout = 30,          -- Connection timeout in seconds
    receive_timeout = 5,             -- Receive timeout in seconds
    ping_interval = 60                -- Ping interval in seconds to keep connection alive
}

-- Game Configuration
config.game = {
    character_save_dir = "saves/",           -- Directory to save character files
    monster_save_dir = "saves/monster/",     -- Directory to save monster files
    max_character_name_length = 50,          -- Maximum character name length
    max_monster_name_length = 50,            -- Maximum monster name length
    max_level = 100,                         -- Maximum level for characters and monsters
    starting_energy = 100,                   -- Starting energy for new characters
    max_dice_roll = 10                       -- Maximum number of dice that can be rolled at once
}

-- Character Classes Configuration
config.character_classes = {
    available = {"human", "mage", "elf", "dwarf", "orc", "troll", "hobbit"},
    base_points = 30                         -- Base attribute points for character creation
}

-- Monster Classes Configuration
config.monster_classes = {
    available = {"werewolf", "vampire", "unicorn", "minotaur", "phoenix", "kraken"}
}

-- Logging Configuration
config.logging = {
    enabled = true,                         -- Enable logging
    level = "info",                        -- Logging level: debug, info, warning, error
    file = "bot.log",                      -- Log file name
    max_size = 1048576                      -- Max log file size in bytes (1MB)
}

-- Return the configuration table
return config