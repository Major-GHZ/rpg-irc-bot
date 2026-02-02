local Create = {}
local Create_mt = { __index = Create }

local function new()
    print("Début de la création de personnage !")
    return setmetatable({}, Create_mt)
end

local function setNumber(prompt)
    while true do
        io.write(prompt)
        local input = io.read("*l")
        local number = tonumber(input)
        if number ~= nil then
            return number
        else
            print("Erreur : veuillez entrer un nombre valide.")
        end
    end
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

    local classChoice = setNumber("Votre choix : ")
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
    character.spells = character.spells[character.class] or {}

    local pointsRestants = 10
    repeat
        print("\nPoints restants : " .. pointsRestants)
        character.attributes.intelligence = setNumber("Intelligence : ")
        character.attributes.strength = setNumber("Strength : ")
        character.attributes.dexterity = setNumber("Dexterity : ")
        character.attributes.endurance = setNumber("Endurance : ")

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

