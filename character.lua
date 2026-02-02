local Create = {}
local Create_mt = { __index = Create }

local function new()
    print("Début de la création de personnage !")
    return setmetatable({}, Create_mt)
end

function Create:newCharacter()
    local character = {
        name = "",
        level = 1,
        attributes = {
            intelligence = 0,
            strength = 0,
            dexterity = 0,
            endurance = 0
        },
        class = "",
        spells = {}
    }

    local classes = {
        "human", "mage", "elf", "dwarf",
        "hobbit", "orc", "goblin", "jedi", "sith"
    }

    print("Entrez le nom de votre personnage :")
    character.name = io.read()

    print("Choisissez une classe (1-9) :")
    for i, class in ipairs(classes) do
        print(i .. ". " .. class)
    end
    local classChoice = tonumber(io.read())
    character.class = classes[classChoice] or "human"

    character.spells = {
        human = {"sword", "bow", "dodge"},
        mage = {"fireball", "lightning", "ice storm"},
        elf = {"sword", "bow", "dodge"},
        dwarf = {"hammer", "axe", "special"},
        hobbit = {"dagger", "sling", "hide"},
        orc = {"club", "axe", "special"},
        goblin = {"dagger", "sword", "bow"},
        jedi = {"lightsaber", "force push", "mind trick"},
        sith = {"dark saber", "force choke", "dark lightning"}
    }

    local pointsRestants = 10
    repeat
        print("\nPoints restants : " .. pointsRestants)
        print("Intelligence :")
        character.attributes.intelligence = tonumber(io.read()) or 0
        print("Strength :")
        character.attributes.strength = tonumber(io.read()) or 0
        print("Dexterity :")
        character.attributes.dexterity = tonumber(io.read()) or 0
        print("Endurance :")
        character.attributes.endurance = tonumber(io.read()) or 0

        pointsRestants = 10 - (character.attributes.intelligence +
                              character.attributes.strength +
                              character.attributes.dexterity +
                              character.attributes.endurance)

        if pointsRestants ~= 0 then
            print("Erreur : la somme doit être égale à 10 !")
        end
    until pointsRestants == 0

    return character
end

return {
    new = new
}

