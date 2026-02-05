local xml = {}

function xml.saveCharacter(character)
    local spells_xml = {}
    for _, spell in ipairs(character.spells) do
        table.insert(spells_xml, "<spell>" .. spell .. "</spell>")
    end
    local spells_str = table.concat(spells_xml, "\n        ")

    local xmlContent = [[
<character>
    <name>]] .. character.name .. [[</name>
    <class>]] .. character.class .. [[</class>
    <level>]] .. character.level .. [[</level>
    <attributes>
        <intelligence>]] .. character.attributes.intelligence .. [[</intelligence>
        <strength>]] .. character.attributes.strength .. [[</strength>
        <dexterity>]] .. character.attributes.dexterity .. [[</dexterity>
        <endurance>]] .. character.attributes.endurance .. [[</endurance>
        <magic>]] .. character.attributes.magic .. [[</magic>
    </attributes>
    <spells>
        ]] .. spells_str .. [[
    </spells>
    <energy>]] .. character.energy .. [[</energy>
    <energyMax>]] .. character.energieMax .. [[</energyMax>
</character>
    ]]

    local filename = "saves/" .. character.name:gsub("[^%w_]", "_") .. ".xml"
    local file = io.open(filename, "w")
    if file then
        file:write(xmlContent)
        file:close()
    else
        print("Error: Unable to save character to file.")
    end
end

-- Function to read an XML file and extract character information
local function readCharacterXML(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    local character = {
        name = filePath:match("saves/(.-)%.xml$"),
        level = tonumber(content:match("<level>(.-)</level>")) or 1,
        experience = tonumber(content:match("<experience>(.-)</experience>")) or 0,
        class = content:match("<class>(.-)</class>") or "Unknown",
        attributes = {
            intelligence = tonumber(content:match("<intelligence>(.-)</intelligence>")) or 0,
            strength = tonumber(content:match("<strength>(.-)</strength>")) or 0,
            dexterity = tonumber(content:match("<dexterity>(.-)</dexterity>")) or 0,
            endurance = tonumber(content:match("<endurance>(.-)</endurance>")) or 0,
            magic = tonumber(content:match("<magic>(.-)</magic>")) or 0
        },
        energy = tonumber(content:match("<energy>(.-)</energy>")) or 0,
        energieMax = tonumber(content:match("<energyMax>(.-)</energyMax>")) or 0,
        spells = {}
    }

    -- Extract spells
    for spell in content:gmatch("<spell>(.-)</spell>") do
        table.insert(character.spells, spell)
    end

    return character
end

-- Function to retrieve a specific character from an XML file
function xml.getCharacterFromXML(player_name)
    local safe_filename = player_name:gsub("[^%w_]", "_")
    return readCharacterXML("saves/" .. safe_filename .. ".xml")
end

-- Function to retrieve all characters from XML files
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
