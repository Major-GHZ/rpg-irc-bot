-- Add Lua modules path
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Load configuration
local config = require("config")

-- Load required modules
local Character = require("character")
local xml = require("character_xml")
local bot = require("irc.bot")

-- Ensure saves directory exists
local function ensure_saves_directory_exists()
    local lfs = require("lfs")
    local path = config.game.character_save_dir
    if not lfs.attributes(path) then
        os.execute("mkdir -p " .. path)
    end
    
    -- Also ensure monster save directory exists
    local monster_path = config.game.monster_save_dir
    if not lfs.attributes(monster_path) then
        os.execute("mkdir -p " .. monster_path)
    end
end

-- Test character creation locally
local function test_character_creation()
    print("=== Local Character Creation Test ===")

    -- Create a custom character
    local customCharacter = Character:createCharacterWithAttributes(
        "Narwen",
        "mage",
        5,
        {intelligence = 20, strength = 0, dexterity = 0, endurance = 0, magic = 10}
    )
    print("\nCustom Character:")
    print("Name: " .. customCharacter.name)
    print("Class: " .. customCharacter.class)
    print("Level: " .. customCharacter.level)
    print("Attributes:")
    print("- Intelligence: " .. customCharacter.attributes.intelligence)
    print("- Strength: " .. customCharacter.attributes.strength)
    print("- Dexterity: " .. customCharacter.attributes.dexterity)
    print("- Endurance: " .. customCharacter.attributes.endurance)
    print("- Magic: " .. customCharacter.attributes.magic)
    print("Spells: " .. table.concat(customCharacter.spells, ", "))
    print("Energy: " .. customCharacter.energy .. "/" .. customCharacter.energieMax)

    -- Save the custom character
    xml.saveCharacter(customCharacter)
    print("\nCharacter saved to XML.")
end

-- Main function
local function main()
    ensure_saves_directory_exists()
    test_character_creation()

    -- Launch IRC bot
    print("\n=== IRC Bot Launch ===")
    bot.run_irc_bot()
end

-- Execute main function
main()
