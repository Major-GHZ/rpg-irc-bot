local Character = require("character")
local xml = require("character_xml")

local character_creation_state = {}

local function handle_character_creation(irc, sender_nick, channel, msg)
    if not character_creation_state[sender_nick] then
        return false
    end

    local state = character_creation_state[sender_nick]

    if state.step == 1 then
        -- Étape 1 : Demander le nom
        state.character.name = msg
        irc:PRIVMSG(channel, sender_nick .. ", choisissez une classe (Guerrier/Mage/Voleur) :")
        state.step = 2
    elseif state.step == 2 then
        -- Étape 2 : Demander la classe
        state.character.class = msg:lower()
        irc:PRIVMSG(channel, sender_nick .. ", entrez le niveau (1-10) :")
        state.step = 3
    elseif state.step == 3 then
        -- Étape 3 : Demander le niveau
        local level = tonumber(msg) or 1
        level = math.max(1, math.min(10, level))  -- Limite entre 1 et 10
        state.character.level = level

        -- Création du personnage
        local character = Character.createCharacterInteractive(
            state.character.name,
            state.character.class,
            state.character.level
        )

        -- Récapitulatif détaillé
        local recap = string.format(
            "%s, récapitulatif de ton personnage :\n" ..
            "Nom: %s\n" ..
            "Classe: %s\n" ..
            "Niveau: %d\n" ..
            "Attributs: Int=%d, Str=%d, Dex=%d, End=%d\n" ..
            "Sorts: %s",
            sender_nick,
            character.name,
            character.class,
            character.level,
            character.attributes.intelligence,
            character.attributes.strength,
            character.attributes.dexterity,
            character.attributes.endurance,
            table.concat(character.spells, ", ")
        )
        irc:PRIVMSG(channel, recap)

        -- Sauvegarde (simulée)
        xml.sauvegarder_personnage(character)

        -- Nettoyage
        character_creation_state[sender_nick] = nil
    end

    return true
end

local function start_character_creation(irc, sender_nick, channel)
    character_creation_state[sender_nick] = {
        step = 1,
        character = {}
    }
    irc:PRIVMSG(channel, sender_nick .. ", entrez le nom de votre personnage :")
end

return {
    handle_character_creation = handle_character_creation,
    start_character_creation = start_character_creation,
}

