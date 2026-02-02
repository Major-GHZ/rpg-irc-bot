local Stage = require("module")
local game = Stage.new()

local CreateCharacter = require("character")
local creator = CreateCharacter.new()
local monPerso = creator:newCharacter()

print("\n--- Récapitulatif ---")
print("Nom : " .. monPerso.name)
print("Classe : " .. monPerso.class)
print("Niveau : " .. monPerso.level)
print("Attributs :")
print("- Intelligence : " .. monPerso.attributes.intelligence)
print("- Strength : " .. monPerso.attributes.strength)
print("- Dexterity : " .. monPerso.attributes.dexterity)
print("- Endurance : " .. monPerso.attributes.endurance)
print("Sorts : " .. table.concat(monPerso.spells[monPerso.class], ", "))

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

