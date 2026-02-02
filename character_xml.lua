-- Function to convert a character table to XML format
local function table_to_xml(character)
    local xml = "<personnage>\n"
    xml = xml .. "    <nom>" .. character.name .. "</nom>\n"
    xml = xml .. "    <niveau>" .. character.level .. "</niveau>\n"
    xml = xml .. "    <classe>" .. character.class .. "</classe>\n"
    xml = xml .. "    <attributs>\n"
    xml = xml .. "        <intelligence>" .. character.attributes.intelligence .. "</intelligence>\n"
    xml = xml .. "        <strength>" .. character.attributes.strength .. "</strength>\n"
    xml = xml .. "        <dexterity>" .. character.attributes.dexterity .. "</dexterity>\n"
    xml = xml .. "        <endurance>" .. character.attributes.endurance .. "</endurance>\n"
    xml = xml .. "    </attributs>\n"
    xml = xml .. "    <sorts>\n"
    for _, spell in ipairs(character.spells) do
        xml = xml .. "        <sort>" .. spell .. "</sort>\n"
    end
    xml = xml .. "    </sorts>\n"
    xml = xml .. "</personnage>"
    return xml
end

-- Function to save a character to an XML file
local function sauvegarder_personnage(character)
    local nom_fichier = character.name .. ".xml"
    local fichier = io.open(nom_fichier, "r")

    -- Check if the file already exists
    if fichier then
        fichier:close()
        print("Error: The file " .. nom_fichier .. " already exists.")
    else
        local xml = table_to_xml(character)
        fichier = io.open(nom_fichier, "w")
        if fichier then
            fichier:write(xml)
            fichier:close()
            print("Character " .. character.name .. " saved successfully.")
        else
            print("Error: Unable to create the file " .. nom_fichier)
        end
    end
end

-- Export the module
return {
    table_to_xml = table_to_xml,
    sauvegarder_personnage = sauvegarder_personnage
}

