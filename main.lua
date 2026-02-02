local Stage = require("module")
local game = Stage.new()

local CreateCharacter = require("character")
local creator = CreateCharacter.new()
local character = creator:newCharacter()

-- Puis, à la fin de la fonction, pour afficher le récapitulatif :
print("\n--- Récapitulatif ---")
print("Nom : " .. character.name)
print("Classe : " .. character.class)
print("Niveau : " .. character.level)
print("Attributs :")
print("- Intelligence : " .. character.attributes.intelligence)
print("- Strength : " .. character.attributes.strength)
print("- Dexterity : " .. character.attributes.dexterity)
print("- Endurance : " .. character.attributes.endurance)
print("Sorts : " .. table.concat(character.spells, ", "))


local hero = { energy = 100, energieMax = 100 }
local boss = { energy = 1000, energieMax = 1000 }

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

