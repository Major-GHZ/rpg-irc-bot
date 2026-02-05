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

return xml
