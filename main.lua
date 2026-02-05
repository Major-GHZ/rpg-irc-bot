-- Ajoute le chemin des modules au package.path
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Import des modules de jeu
local Character = require("character")
local Level = require("level")
local Stage = require("stage")
local xml = require("character_xml")

package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

local bot = require("irc.bot")
bot.run()


-- =============================================
-- Logique de démonstration locale (optionnelle)
-- =============================================
local function run_local_demo()
    -- Création d'un personnage par défaut
    local character = Character.new()
    local hero = character:newCharacter()

    -- Affichage des informations du personnage
    print("\n--- Résumé du personnage ---")
    print("Nom: " .. hero.name)
    print("Classe: " .. hero.class)
    print("Niveau: " .. hero.level)
    print("Attributs:")
    print("- Intelligence: " .. hero.attributes.intelligence)
    print("- Force: " .. hero.attributes.strength)
    print("- Dextérité: " .. hero.attributes.dexterity)
    print("- Endurance: " .. hero.attributes.endurance)
    print("Sorts: " .. table.concat(hero.spells, ", "))

    -- Sauvegarde du personnage
    xml.sauvegarder_personnage(hero)

    -- Simulation de combat
    local hero_combat = { energy = 100, energieMax = 100 }
    local boss = { energy = 1000, energieMax = 1000 }
    local level = Level.new()

    print("\n--- Simulation de combat ---")
    level:newDamage(hero_combat, 5)
    print("Énergie du héros :", hero_combat.energy)

    level:newDamage(boss, 45)
    print("Énergie du boss :", boss.energy)

    level:newDamage(hero_combat, 5)
    print("Énergie du héros :", hero_combat.energy)

    level:newDamage(boss, 45)
    print("Énergie du boss :", boss.energy)

    level:newDamage(hero_combat, 5)
    print("Énergie du héros :", hero_combat.energy)

    level:newDamage(boss, 45)
    print("Énergie du boss :", boss.energy)
end

-- Exécute la démonstration locale (optionnel)
run_local_demo()

-- =============================================
-- Lancement du bot IRC
-- =============================================
local bot = require("irc.bot")
bot.run()

