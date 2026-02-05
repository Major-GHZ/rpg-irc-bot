local Character = require("character")
local xml = require("character_xml")

local character_creation_state = {}
local characters = {}

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

        local character = Character.createCharacterInteractive(
            state.character.name,
            state.character.class,
            state.character.level
        )

        characters[sender_nick] = character

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

local function show_character_recap(irc, sender_nick, channel)
    local character = characters[sender_nick]
    if character then
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
    else
        irc:PRIVMSG(channel, sender_nick .. ", tu n'as pas encore créé de personnage.")
    end
end

local function show_help(irc, sender_nick, channel)
    local help_message = string.format(
        "%s, voici les commandes disponibles :\n" ..
        "!create : Créer un personnage.\n" ..
        "!recap : Afficher le récapitulatif de ton personnage.\n" ..
        "!ping : Vérifier si le bot est actif.\n" ..
        "!salut : Dire bonjour au bot.\n" ..
        "!help : Afficher ce message d'aide.",
        sender_nick
    )
    irc:PRIVMSG(channel, help_message)
end

return {
    handle_character_creation = handle_character_creation,
    start_character_creation = start_character_creation,
    show_character_recap = show_character_recap,
    show_help = show_help,
}

