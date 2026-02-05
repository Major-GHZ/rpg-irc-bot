local xml = {}

function xml.sauvegarder_personnage(character)
    local spells_xml = {}
    for _, spell in ipairs(character.spells) do
        table.insert(spells_xml, "<sort>" .. spell .. "</sort>")
    end
    local spells_str = table.concat(spells_xml, "\n        ")

    local xmlContent = [[
<personnage>
    <nom>]] .. character.name .. [[</nom>
    <classe>]] .. character.class .. [[</classe>
    <niveau>]] .. character.level .. [[</niveau>
    <attributs>
        <intelligence>]] .. character.attributes.intelligence .. [[</intelligence>
        <strength>]] .. character.attributes.strength .. [[</strength>
        <dexterity>]] .. character.attributes.dexterity .. [[</dexterity>
        <endurance>]] .. character.attributes.endurance .. [[</endurance>
        <magic>]] .. character.attributes.magic .. [[</magic>
    </attributs>
    <sorts>
        ]] .. spells_str .. [[
    </sorts>
    <energie>]] .. character.energy .. [[</energie>
    <energieMax>]] .. character.energieMax .. [[</energieMax>
</personnage>
    ]]

    local filename = "saves/" .. character.name:gsub("[^%w_]", "_") .. ".xml"
    local file = io.open(filename, "w")
    if file then
        file:write(xmlContent)
        file:close()
    else
        print("Erreur: Impossible de sauvegarder le personnage dans un fichier.")
    end
end

-- Fonction pour lire un fichier XML et extraire les informations du personnage
local function readCharacterXML(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    local character = {
        name = filePath:match("saves/(.-)%.xml$"),
        level = tonumber(content:match("<niveau>(.-)</niveau>")) or 1,
        experience = tonumber(content:match("<experience>(.-)</experience>")) or 0,
        class = content:match("<classe>(.-)</classe>") or "Inconnu",
        attributes = {
            intelligence = tonumber(content:match("<intelligence>(.-)</intelligence>")) or 0,
            strength = tonumber(content:match("<strength>(.-)</strength>")) or 0,
            dexterity = tonumber(content:match("<dexterity>(.-)</dexterity>")) or 0,
            endurance = tonumber(content:match("<endurance>(.-)</endurance>")) or 0,
            magic = tonumber(content:match("<magic>(.-)</magic>")) or 0
        },
        energy = tonumber(content:match("<energie>(.-)</energie>")) or 0,
        energieMax = tonumber(content:match("<energieMax>(.-)</energieMax>")) or 0,
        spells = {}
    }

    -- Extraire les sorts
    for spell in content:gmatch("<sort>(.-)</sort>") do
        table.insert(character.spells, spell)
    end

    return character
end

-- Fonction pour récupérer tous les personnages depuis les fichiers XML
function xml.getAllCharactersFromXML()
    local characters = {}
    local files = io.popen("ls saves/"):lines()

    for file in files do
        if file:match("%.xml$") then
            local character = readCharacterXML("saves/" .. file)
            if character then
                characters[character.name] = character
            end
        end
    end

    return characters
end

return xml
