-- Ajoute le chemin des modules Lua
package.path = package.path .. ";./modules/?.lua;./modules/irc/?.lua"

-- Charge les modules nécessaires
local Character = require("character")
local xml = require("character_xml")
local bot = require("irc.bot")

-- Crée un dossier pour les sauvegardes XML si nécessaire
local function ensure_saves_directory_exists()
    local lfs = require("lfs")
    local path = "saves"
    if not lfs.attributes(path) then
        os.execute("mkdir -p " .. path)
    end
end

-- Teste la création de personnage localement
local function test_character_creation()
    print("=== Test de création de personnage local ===")

    -- Crée un personnage personnalisé
    local customCharacter = Character:createCharacterWithAttributes(
        "Narwen",
        "mage",
        5,
        {intelligence = 20, strength = 0, dexterity = 0, endurance = 0, magic = 10}
    )
    print("\nPersonnage personnalisé :")
    print("Nom : " .. customCharacter.name)
    print("Classe : " .. customCharacter.class)
    print("Niveau : " .. customCharacter.level)
    print("Attributs :")
    print("- Intelligence : " .. customCharacter.attributes.intelligence)
    print("- Force : " .. customCharacter.attributes.strength)
    print("- Dextérité : " .. customCharacter.attributes.dexterity)
    print("- Endurance : " .. customCharacter.attributes.endurance)
    print("- Magie : " .. customCharacter.attributes.magic)
    print("Sorts : " .. table.concat(customCharacter.spells, ", "))
    print("Énergie : " .. customCharacter.energy .. "/" .. customCharacter.energieMax)

    -- Sauvegarde le personnage personnalisé
    xml.sauvegarder_personnage(customCharacter)
    print("\nPersonnage sauvegardé en XML.")
end

-- Fonction principale
local function main()
    ensure_saves_directory_exists()
    test_character_creation()

    -- Lance le bot IRC
    print("\n=== Lancement du bot IRC ===")
    bot.run_irc_bot()
end

-- Exécute la fonction principale
main()
