-- Fichier : modules/monster_creation.lua
-- Module complet pour la création et gestion des monstres d'heroic fantasy

local M = {}

-- Définition des classes de monstres directement dans le module
M.monster_classes = {
    -- Loup-garou
    loup_garou = {
        name = "Loup-garou",
        description = "Un monstre rapide et puissant, capable de se transformer.",
        base_attributes = {
            intelligence = 4,
            strength = 8,
            dexterity = 7,
            endurance = 6,
            magic = 3
        },
        base_spells = {"Griffes acérées", "Hurlement terrifiant", "Transformation"},
        base_health = 60,
        base_health_max = 60,
        base_damage = 10,
        base_armor = 5
    },
    
    -- Vampire
    vampire = {
        name = "Vampire",
        description = "Un monstre immortel avec des capacités de régénération.",
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
        description = "Un monstre magique avec des capacités de guérison.",
        base_attributes = {
            intelligence = 6,
            strength = 5,
            dexterity = 7,
            endurance = 6,
            magic = 8
        },
        base_spells = {"Corne de guérison", "Bénédiction", "Purification"},
        base_health = 80,
        base_health_max = 80,
        base_damage = 8,
        base_armor = 6
    },
    
    -- Minotaure
    minotaure = {
        name = "Minotaure",
        description = "Un monstre puissant et résistant.",
        base_attributes = {
            intelligence = 3,
            strength = 9,
            dexterity = 4,
            endurance = 8,
            magic = 2
        },
        base_spells = {"Charge puissante", "Résistance", "Coup de corne"},
        base_health = 90,
        base_health_max = 90,
        base_damage = 12,
        base_armor = 7
    },
    
    -- Phénix
    phenix = {
        name = "Phénix",
        description = "Un monstre magique capable de renaître de ses cendres.",
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
        description = "Un monstre marin géant avec des tentacules puissants.",
        base_attributes = {
            intelligence = 5,
            strength = 10,
            dexterity = 5,
            endurance = 9,
            magic = 4
        },
        base_spells = {"Étouffement", "Vague géante", "Résistance aquatique"},
        base_health = 120,
        base_health_max = 120,
        base_damage = 14,
        base_armor = 8
    }
}

-- Fonction pour obtenir une classe de monstre par son nom
function M.getMonsterClass(monster_class_name)
    if not monster_class_name or type(monster_class_name) ~= "string" then
        return nil
    end
    
    -- Essayer de trouver la classe (insensible à la casse)
    local class_name = monster_class_name:lower()
    return M.monster_classes[class_name]
end

-- Fonction pour obtenir la liste des classes de monstres disponibles
function M.getAvailableMonsterClasses()
    local class_list = {}
    for class_name, class_info in pairs(M.monster_classes) do
        table.insert(class_list, class_name)
    end
    return class_list
end

-- Fonction pour valider un nom de monstre
local function validateMonsterName(name)
    if not name or type(name) ~= "string" or name:match("^%s*$") then
        return nil, "Le nom du monstre ne peut pas être vide"
    end
    if #name > 50 then
        return nil, "Le nom du monstre ne peut pas dépasser 50 caractères"
    end
    -- Vérification simplifiée des caractères invalides
    if name:find("<") or name:find(">") or name:find("|") or name:find("\\") or name:find("/") then
        return nil, "Le nom du monstre contient des caractères invalides"
    end
    return true
end

-- Fonction pour valider un niveau
local function validateLevel(level)
    if not level then return nil, "Le niveau est requis" end
    level = tonumber(level)
    if not level or level < 1 or level > 100 then
        return nil, "Le niveau doit être un nombre entre 1 et 100"
    end
    return level
end

-- Fonction pour créer un monstre avec une classe spécifique
function M.createMonster(monster_name, monster_class_name, level)
    -- Validation des paramètres d'entrée
    local valid_name, name_err = validateMonsterName(monster_name)
    if not valid_name then
        return nil, name_err
    end
    
    if not monster_class_name or type(monster_class_name) ~= "string" then
        return nil, "La classe de monstre est requise"
    end
    
    local validated_level, level_err = validateLevel(level)
    if not validated_level then
        return nil, level_err
    end
    
    local monster_class = M.getMonsterClass(monster_class_name)
    if not monster_class then
        return nil, "Classe de monstre invalide. Classes disponibles : " .. table.concat(M.getAvailableMonsterClasses(), ", ")
    end

    -- Vérification que la classe de monstre a toutes les propriétés requises
    if not monster_class.base_attributes or not monster_class.base_spells or
       not monster_class.base_health or not monster_class.base_damage or
       not monster_class.base_armor then
        return nil, "La classe de monstre " .. monster_class_name .. " est mal configurée"
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

    -- Appliquer les attributs de base de la classe avec validation
    for attribute, value in pairs(monster_class.base_attributes) do
        if type(value) == "number" and value > 0 then
            monster.attributes[attribute] = value * monster.level
        else
            monster.attributes[attribute] = 0
        end
    end

    -- Vérification finale que le monstre est valide
    if not monster.name or not monster.class or not monster.level or
       not monster.health or not monster.damage then
        return nil, "Erreur lors de la création du monstre"
    end

    return monster
end

-- Fonction pour créer un répertoire si nécessaire
local function ensureDirectoryExists(path)
    local success, err = os.execute("mkdir -p " .. path)
    if not success then
        -- Essayer une approche alternative pour Windows
        local ok, err2 = os.execute("mkdir " .. path .. " 2>nul")
        if not ok then
            return false, "Impossible de créer le répertoire: " .. path .. " (" .. tostring(err) .. ", " .. tostring(err2) .. ")"
        end
    end
    return true
end

-- Fonction pour échapper les caractères XML
local function escapeXml(text)
    if not text then return "" end
    return tostring(text)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub("'", "&apos;")
        :gsub("\"", "&quot;")
end

-- Fonction pour sauvegarder un monstre dans un fichier XML
function M.saveMonster(monster)
    -- Validation du monstre
    if not monster or type(monster) ~= "table" then
        return false, "Monstre invalide"
    end
    
    if not monster.name or not monster.class or not monster.level then
        return false, "Monstre incomplet - informations manquantes"
    end
    
    -- Créer le répertoire si nécessaire
    local dir_success, dir_err = ensureDirectoryExists("saves/monster")
    if not dir_success then
        return false, "Erreur de répertoire: " .. dir_err
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
        safe_filename = "monstre_inconnu"
    end
    
    local filename = "saves/monster/" .. safe_filename .. ".xml"
    
    -- Sauvegarder le fichier
    local file, open_err = io.open(filename, "w")
    if not file then
        return false, "Impossible d'ouvrir le fichier pour écriture: " .. tostring(open_err)
    end
    
    local write_success, write_err = pcall(function()
        file:write(xmlContent)
        file:close()
    end)
    
    if not write_success then
        file:close()
        return false, "Erreur lors de l'écriture du fichier: " .. tostring(write_err)
    end
    
    return true
end

-- Fonction pour lister les fichiers d'un répertoire (multiplateforme)
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

-- Fonction pour charger un monstre depuis un fichier XML
function M.loadMonster(filePath)
    if not filePath or type(filePath) ~= "string" then
        return nil, "Chemin de fichier invalide"
    end

    local file, open_err = io.open(filePath, "r")
    if not file then
        return nil, "Impossible d'ouvrir le fichier: " .. tostring(open_err)
    end

    local content, read_err = file:read("*a")
    file:close()
    
    if not content then
        return nil, "Impossible de lire le fichier: " .. tostring(read_err)
    end

    -- Vérifier que le contenu ressemble à du XML
    if not content:match("^%s*<monster>") then
        return nil, "Fichier XML invalide - format incorrect"
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
        return nil, "Erreur lors du chargement des sorts: " .. tostring(err)
    end

    -- Validation finale
    if not monster.name or not monster.class or not monster.level then
        return nil, "Fichier XML corrompu - informations manquantes"
    end

    return monster
end

-- Fonction pour lister tous les monstres sauvegardés
function M.listMonsters()
    local monsters = {}
    
    -- Vérifier que le répertoire existe
    local dir_success, dir_err = ensureDirectoryExists("saves/monster")
    if not dir_success then
        return monsters, "Avertissement: " .. dir_err
    end
    
    local files, list_err = listDirectoryFiles("saves/monster")
    if not files then
        return monsters, "Erreur lors de la lecture du répertoire: " .. tostring(list_err)
    end

    for _, file in ipairs(files) do
        if file:match("%.xml$") then
            local monster, load_err = M.loadMonster("saves/monster/" .. file)
            if monster then
                table.insert(monsters, monster)
            else
                -- Journaliser l'erreur mais continuer
                print("Avertissement: Impossible de charger " .. file .. ": " .. tostring(load_err))
            end
        end
    end

    -- Trier les monstres par nom
    table.sort(monsters, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return monsters
end

-- Fonction pour obtenir des informations sur une classe de monstre
function M.getMonsterClassInfo(class_name)
    local class = M.getMonsterClass(class_name)
    if not class then
        return nil, "Classe de monstre invalide"
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

-- Fonction pour obtenir la liste complète des classes avec détails
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