-- File: modules/monster_creation.lua
-- Complete module for creating and managing heroic fantasy monsters

local config = require("config")

local M = {}

-- Definition of monster classes directly in the module
M.monster_classes = {
    -- Werewolf
    loup_garou = {
        name = "Werewolf",
        description = "A fast and powerful monster, capable of transforming.",
        base_attributes = {
            intelligence = 4,
            strength = 8,
            dexterity = 7,
            endurance = 6,
            magic = 3
        },
        base_spells = {"Sharp Claws", "Terrifying Howl", "Transformation"},
        base_health = 60,
        base_health_max = 60,
        base_damage = 10,
        base_armor = 5
    },
    
    -- Vampire
    vampire = {
        name = "Vampire",
        description = "An immortal monster with regeneration abilities.",
        base_attributes = {
            intelligence = 7,
            strength = 6,
            dexterity = 8,
            endurance = 5,
            magic = 7
        },
        base_spells = {"Morsure vampirique", "Régénération", "Hypnose"},
        base_health = 70,
        base_health_max = 70,
        base_damage = 9,
        base_armor = 4
    },
    
    -- Licorne
    licorne = {
        name = "Licorne",
        description = "A magical monster with healing abilities.",
        base_attributes = {
            intelligence = 6,
            strength = 5,
            dexterity = 7,
            endurance = 6,
            magic = 8
        },
        base_spells = {"Healing Horn", "Blessing", "Purification"},
        base_health = 80,
        base_health_max = 80,
        base_damage = 8,
        base_armor = 6
    },
    
    -- Minotaure
    minotaure = {
        name = "Minotaure",
        description = "A powerful and resistant monster.",
        base_attributes = {
            intelligence = 3,
            strength = 9,
            dexterity = 4,
            endurance = 8,
            magic = 2
        },
        base_spells = {"Powerful Charge", "Resistance", "Horn Strike"},
        base_health = 90,
        base_health_max = 90,
        base_damage = 12,
        base_armor = 7
    },
    
    -- Phénix
    phenix = {
        name = "Phénix",
        description = "A magical monster capable of rebirth from its ashes.",
        base_attributes = {
            intelligence = 8,
            strength = 6,
            dexterity = 6,
            endurance = 7,
            magic = 9
        },
        base_spells = {"Souffle de feu", "Renaissance", "Vol"},
        base_health = 100,
        base_health_max = 100,
        base_damage = 11,
        base_armor = 5
    },
    
    -- Kraken
    kraken = {
        name = "Kraken",
        description = "A giant sea monster with powerful tentacles.",
        base_attributes = {
            intelligence = 5,
            strength = 10,
            dexterity = 5,
            endurance = 9,
            magic = 4
        },
        base_spells = {"Suffocation", "Giant Wave", "Water Resistance"},
        base_health = 120,
        base_health_max = 120,
        base_damage = 14,
        base_armor = 8
    }
}

-- Function to get a monster class by name
function M.getMonsterClass(monster_class_name)
    if not monster_class_name or type(monster_class_name) ~= "string" then
        return nil
    end
    
    -- Try to find the class (case insensitive)
    local class_name = monster_class_name:lower()
    return M.monster_classes[class_name]
end

-- Function to get the list of available monster classes
function M.getAvailableMonsterClasses()
    local class_list = {}
    for class_name, class_info in pairs(M.monster_classes) do
        table.insert(class_list, class_name)
    end
    return class_list
end

-- Function to validate a monster name
local function validateMonsterName(name)
    if not name or type(name) ~= "string" or name:match("^%s*$") then
        return nil, "Monster name cannot be empty"
    end
    if #name > config.game.max_monster_name_length then
        return nil, "Monster name cannot exceed " .. config.game.max_monster_name_length .. " characters"
    end
    -- Simplified check for invalid characters
    if name:find("<") or name:find(">") or name:find("|") or name:find("\\") or name:find("/") then
        return nil, "Monster name contains invalid characters"
    end
    return true
end

-- Function to validate a level
local function validateLevel(level)
    if not level then return nil, "Level is required" end
    level = tonumber(level)
    if not level or level < 1 or level > config.game.max_level then
        return nil, "Level must be a number between 1 and " .. config.game.max_level
    end
    return level
end

-- Function to create a monster with a specific class
function M.createMonster(monster_name, monster_class_name, level)
    -- Validation des paramètres d'entrée
    local valid_name, name_err = validateMonsterName(monster_name)
    if not valid_name then
        return nil, name_err
    end
    
    if not monster_class_name or type(monster_class_name) ~= "string" then
        return nil, "Monster class is required"
    end
    
    local validated_level, level_err = validateLevel(level)
    if not validated_level then
        return nil, level_err
    end
    
    local monster_class = M.getMonsterClass(monster_class_name)
    if not monster_class then
        return nil, "Invalid monster class. Available classes: " .. table.concat(M.getAvailableMonsterClasses(), ", ")
    end

    -- Check that the monster class has all required properties
    if not monster_class.base_attributes or not monster_class.base_spells or
       not monster_class.base_health or not monster_class.base_damage or
       not monster_class.base_armor then
        return nil, "Monster class " .. monster_class_name .. " is misconfigured"
    end

    local monster = {}
    monster.name = monster_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    monster.class = monster_class.name
    monster.level = validated_level
    monster.attributes = {}
    monster.spells = monster_class.base_spells or {}
    monster.health = (monster_class.base_health or 0) * monster.level
    monster.health_max = (monster_class.base_health_max or monster_class.base_health or 0) * monster.level
    monster.damage = (monster_class.base_damage or 0) * monster.level
    monster.armor = (monster_class.base_armor or 0) * monster.level

    -- Apply the class's base attributes with validation
    for attribute, value in pairs(monster_class.base_attributes) do
        if type(value) == "number" and value > 0 then
            monster.attributes[attribute] = value * monster.level
        else
            monster.attributes[attribute] = 0
        end
    end

    -- Final check that the monster is valid
    if not monster.name or not monster.class or not monster.level or
       not monster.health or not monster.damage then
        return nil, "Error creating monster"
    end

    return monster
end

-- Function to create a directory if needed
local function ensureDirectoryExists(path)
    local success, err = os.execute("mkdir -p " .. path)
    if not success then
        -- Essayer une approche alternative pour Windows
        local ok, err2 = os.execute("mkdir " .. path .. " 2>nul")
        if not ok then
            return false, "Unable to create directory: " .. path .. " (" .. tostring(err) .. ", " .. tostring(err2) .. ")"
        end
    end
    return true
end

-- Function to escape XML characters
local function escapeXml(text)
    if not text then return "" end
    return tostring(text)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub("'", "&apos;")
        :gsub("\"", "&quot;")
end

-- Function to save a monster to an XML file
function M.saveMonster(monster)
    -- Monster validation
    if not monster or type(monster) ~= "table" then
        return false, "Invalid monster"
    end
    
    if not monster.name or not monster.class or not monster.level then
        return false, "Incomplete monster - missing information"
    end
    
    -- Créer le répertoire si nécessaire
    local dir_success, dir_err = ensureDirectoryExists("saves/monster")
    if not dir_success then
        return false, "Directory error: " .. dir_err
    end
    
    -- Préparer les sorts
    local spells_xml = {}
    if monster.spells and #monster.spells > 0 then
        for _, spell in ipairs(monster.spells) do
            table.insert(spells_xml, "<spell>" .. escapeXml(tostring(spell)) .. "</spell>")
        end
    end
    local spells_str = table.concat(spells_xml, "\n        ")

    -- Échapper les valeurs XML
    local safe_name = escapeXml(monster.name)
    local safe_class = escapeXml(monster.class)
    local safe_level = tostring(monster.level or 1)
    
    local safe_attrs = {
        intelligence = tostring(monster.attributes and monster.attributes.intelligence or 0),
        strength = tostring(monster.attributes and monster.attributes.strength or 0),
        dexterity = tostring(monster.attributes and monster.attributes.dexterity or 0),
        endurance = tostring(monster.attributes and monster.attributes.endurance or 0),
        magic = tostring(monster.attributes and monster.attributes.magic or 0)
    }
    
    local safe_stats = {
        health = tostring(monster.health or 0),
        health_max = tostring(monster.health_max or 0),
        damage = tostring(monster.damage or 0),
        armor = tostring(monster.armor or 0)
    }

    local xmlContent = [[
<monster>
    <name>]] .. safe_name .. [[</name>
    <class>]] .. safe_class .. [[</class>
    <level>]] .. safe_level .. [[</level>
    <attributes>
        <intelligence>]] .. safe_attrs.intelligence .. [[</intelligence>
        <strength>]] .. safe_attrs.strength .. [[</strength>
        <dexterity>]] .. safe_attrs.dexterity .. [[</dexterity>
        <endurance>]] .. safe_attrs.endurance .. [[</endurance>
        <magic>]] .. safe_attrs.magic .. [[</magic>
    </attributes>
    <spells>
        ]] .. spells_str .. [[
    </spells>
    <health>]] .. safe_stats.health .. [[</health>
    <health_max>]] .. safe_stats.health_max .. [[</health_max>
    <damage>]] .. safe_stats.damage .. [[</damage>
    <armor>]] .. safe_stats.armor .. [[</armor>
</monster>
    ]]

    -- Générer un nom de fichier sûr
    local safe_filename = monster.name:gsub("[^%w_]", "_")
    if #safe_filename == 0 then
        safe_filename = "unknown_monster"
    end
    
    local filename = "saves/monster/" .. safe_filename .. ".xml"
    
    -- Sauvegarder le fichier
    local file, open_err = io.open(filename, "w")
    if not file then
        return false, "Unable to open file for writing: " .. tostring(open_err)
    end
    
    local write_success, write_err = pcall(function()
        file:write(xmlContent)
        file:close()
    end)
    
    if not write_success then
        file:close()
        return false, "Error writing to file: " .. tostring(write_err)
    end
    
    return true
end

-- Function to list files in a directory (cross-platform)
local function listDirectoryFiles(dir_path)
    local files = {}
    
    -- Essayer d'abord avec io.popen (Unix/Linux/Mac)
    local handle, err = io.popen("ls " .. dir_path .. " 2>/dev/null")
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
        return files
    end
    
    -- Approche alternative pour Windows ou si io.popen échoue
    local lfs = pcall(require, "lfs")
    if lfs then
        local lfs = require("lfs")
        for file in lfs.dir(dir_path) do
            if file ~= "." and file ~= ".." then
                table.insert(files, file)
            end
        end
        return files
    end
    
    -- Dernière tentative avec une approche basique
    local i = 0
    while true do
        local file = io.open(dir_path .. "/file" .. i .. ".xml", "r")
        if not file then break end
        file:close()
        table.insert(files, "file" .. i .. ".xml")
        i = i + 1
    end
    
    return files
end

-- Function to load a monster from an XML file
function M.loadMonster(filePath)
    if not filePath or type(filePath) ~= "string" then
        return nil, "Chemin de fichier invalide"
    end

    local file, open_err = io.open(filePath, "r")
    if not file then
        return nil, "Unable to open file: " .. tostring(open_err)
    end

    local content, read_err = file:read("*a")
    file:close()
    
    if not content then
        return nil, "Unable to read file: " .. tostring(read_err)
    end

    -- Vérifier que le contenu ressemble à du XML
    if not content:match("^%s*<monster>") then
        return nil, "Invalid XML file - incorrect format"
    end

    local monster = {
        name = content:match("<name>(.-)</name>") or "Inconnu",
        class = content:match("<class>(.-)</class>") or "Inconnu",
        level = tonumber(content:match("<level>(.-)</level>")) or 1,
        attributes = {
            intelligence = tonumber(content:match("<intelligence>(.-)</intelligence>")) or 0,
            strength = tonumber(content:match("<strength>(.-)</strength>")) or 0,
            dexterity = tonumber(content:match("<dexterity>(.-)</dexterity>")) or 0,
            endurance = tonumber(content:match("<endurance>(.-)</endurance>")) or 0,
            magic = tonumber(content:match("<magic>(.-)</magic>")) or 0
        },
        spells = {},
        health = tonumber(content:match("<health>(.-)</health>")) or 0,
        health_max = tonumber(content:match("<health_max>(.-)</health_max>")) or 0,
        damage = tonumber(content:match("<damage>(.-)</damage>")) or 0,
        armor = tonumber(content:match("<armor>(.-)</armor>")) or 0
    }

    -- Extraire les sorts avec protection contre les erreurs
    local success, err = pcall(function()
        for spell in content:gmatch("<spell>(.-)</spell>") do
            if spell and #spell > 0 then
                table.insert(monster.spells, spell)
            end
        end
    end)
    
    if not success then
        return nil, "Error loading spells: " .. tostring(err)
    end

    -- Validation finale
    if not monster.name or not monster.class or not monster.level then
        return nil, "Corrupted XML file - missing information"
    end

    return monster
end

-- Function to list all saved monsters
function M.listMonsters()
    local monsters = {}
    
    -- Vérifier que le répertoire existe
    local dir_success, dir_err = ensureDirectoryExists("saves/monster")
    if not dir_success then
        return monsters, "Warning: " .. dir_err
    end
    
    local files, list_err = listDirectoryFiles("saves/monster")
    if not files then
        return monsters, "Error reading directory: " .. tostring(list_err)
    end

    for _, file in ipairs(files) do
        if file:match("%.xml$") then
            local monster, load_err = M.loadMonster("saves/monster/" .. file)
            if monster then
                table.insert(monsters, monster)
            else
                -- Journaliser l'erreur mais continuer
                print("Warning: Unable to load " .. file .. ": " .. tostring(load_err))
            end
        end
    end

    -- Sort monsters by name
    table.sort(monsters, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return monsters
end

-- Function to get information about a monster class
function M.getMonsterClassInfo(class_name)
    local class = M.getMonsterClass(class_name)
    if not class then
        return nil, "Invalid monster class"
    end
    
    return {
        name = class.name,
        description = class.description,
        base_attributes = class.base_attributes,
        base_spells = class.base_spells,
        base_health = class.base_health,
        base_damage = class.base_damage,
        base_armor = class.base_armor
    }
end

-- Function to get the complete list of classes with details
function M.getAllMonsterClassesWithDetails()
    local classes = {}
    for class_name, class_info in pairs(M.monster_classes) do
        table.insert(classes, {
            name = class_name,
            display_name = class_info.name,
            description = class_info.description,
            spells = class_info.base_spells
        })
    end
    
    -- Trier par nom
    table.sort(classes, function(a, b)
        return a.display_name:lower() < b.display_name:lower()
    end)
    
    return classes
end

return M