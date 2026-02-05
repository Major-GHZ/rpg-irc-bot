-- Import the Stage module and create a new game instance
local Stage = require("module")
local game = Stage.new()

-- Import the character creation module and create a new character
local CreateCharacter = require("character")
local create = CreateCharacter.new()
local character = create:newCharacter()

-- Print character summary
print("\n--- Summary ---")
print("Name: " .. character.name)
print("Class: " .. character.class)
print("Level: " .. character.level)
print("Attributes:")
print("- Intelligence: " .. character.attributes.intelligence)
print("- Strength: " .. character.attributes.strength)
print("- Dexterity: " .. character.attributes.dexterity)
print("- Endurance: " .. character.attributes.endurance)
print("Spells: " .. table.concat(character.spells, ", "))

-- Load the XML save module and save the character
local xml = require("character_xml")
xml.sauvegarder_personnage(character)

-- Define hero and boss with energy values
local hero = { energy = 100, energieMax = 100 }
local boss = { energy = 1000, energieMax = 1000 }

-- Apply damage to hero and boss, then print their energy
game:newDamage(hero, 5)
print("Hero Energy", hero.energy)

game:newDamage(boss, 45)
print("Boss Energy", boss.energy)

game:newDamage(hero, 5)
print("Hero Energy", hero.energy)

game:newDamage(boss, 45)
print("Boss Energy", boss.energy)

game:newDamage(hero, 5)
print("Hero Energy", hero.energy)

game:newDamage(boss, 45)
print("Boss Energy", boss.energy)
