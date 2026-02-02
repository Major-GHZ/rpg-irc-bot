-- Character creation module
local Create = {}
local Create_mt = { __index = Create }

-- Constructor for the character creation module
local function new()
    print("Starting character creation!")
    return setmetatable({}, Create_mt)
end

-- Helper function to get a valid number from user input
local function setNumber(prompt)
    while true do
        io.write(prompt)
        local input = io.read("*l")
        local number = tonumber(input)
        if number ~= nil then
            return number
        else
            print("Error: Please enter a valid number.")
        end
    end
end

-- Function to create a new character
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

    -- Available character classes
    local classes = {
        "human", "mage", "elf", "dwarf",
        "hobbit", "orc", "goblin", "jedi", "sith"
    }

    -- Prompt for character name
    print("Enter your character's name:")
    character.name = io.read()

    -- Prompt for character class
    print("Choose a class (1-9):")
    for i, class in ipairs(classes) do
        print(i .. ". " .. class)
    end

    local classChoice = setNumber("Your choice: ")
    character.class = classes[classChoice] or "human"

    -- Assign spells based on class
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

    -- Attribute points distribution (must sum to 10)
    local pointsRestants = 10
    repeat
        print("\nRemaining points: " .. pointsRestants)
        character.attributes.intelligence = setNumber("Intelligence: ")
        character.attributes.strength = setNumber("Strength: ")
        character.attributes.dexterity = setNumber("Dexterity: ")
        character.attributes.endurance = setNumber("Endurance: ")

        pointsRestants = 10 - (character.attributes.intelligence +
                              character.attributes.strength +
                              character.attributes.dexterity +
                              character.attributes.endurance)

        if pointsRestants ~= 0 then
            print("Error: The sum must equal 10!")
        end
    until pointsRestants == 0

    return character
end

-- Export the module
return {
    new = new
}

