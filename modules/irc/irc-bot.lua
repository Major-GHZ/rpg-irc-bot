-- Modules de jeu
local Character = require("character")
local xml = require("character_xml")

-- État pour la création de personnage via IRC
local character_creation_state = {}

local function handle_character_creation(irc, sender_nick, channel, msg)
    if not character_creation_state[sender_nick] then
        return false
    end

    local state = character_creation_state[sender_nick]

    if state.step == 1 then
        state.character.name = msg
        irc:PRIVMSG(channel, sender_nick .. ", choisissez une classe (Guerrier/Mage/Voleur) :")
        state.step = 2
    elseif state.step == 2 then
        state.character.class = msg:lower()
        irc:PRIVMSG(channel, sender_nick .. ", entrez le niveau (1-10) :")
        state.step = 3
    elseif state.step == 3 then
        local level = tonumber(msg) or 1
        level = math.max(1, math.min(10, level))
        state.character.level = level

        local character = Character:createCharacter(
            state.character.name,
            state.character.class,
            state.character.level
        )

        local recap = string.format(
            "%s, ton personnage a été créé : %s (%s, Niveau %d). Attributs: Int=%d, Str=%d, Dex=%d, End=%d. Sorts: %s",
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
        xml.sauvegarder_personnage(character)
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

-- Gestion des commandes IRC
local function handle_irc_command(irc, sender_nick, channel, msg)
    if msg:lower():match("^!create") then
        start_character_creation(irc, sender_nick, channel)
    elseif character_creation_state[sender_nick] then
        handle_character_creation(irc, sender_nick, channel, msg)
    end
end

return {
    handle_irc_command = handle_irc_command,
}
