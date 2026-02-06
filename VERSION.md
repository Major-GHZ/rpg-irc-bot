# RPG IRC Bot - Version History

## Version 0.3.0 (Current)
**Release Date:** 2024

### 🚀 Major Features
- **Complete Anglification** - All code, messages, and comments translated to English
- **Command Renaming** - All commands now use English names only
- **Configuration System** - Centralized config.lua for all bot parameters
- **Improved Structure** - Cleaner code organization and better separation of concerns

### 📋 New Features
- **!createplayer** - Create player characters with interactive 7-step process
- **!listplayer** - List all saved player characters
- **!getplayer <name>** - Load specific character by name
- **!stats** - Show character statistics and information
- **!createmonster** - Create monsters with Health/Damage/Armor system
- **!listmonsters** - List all created monsters
- **!roll <number>** - Roll dice (1-10 dice)
- **!hello** - Friendly greeting command
- **!help** - Comprehensive help system
- **!ping** - Connection test

### 🔧 Technical Improvements
- **Centralized Configuration** - All settings in config.lua
- **XML Persistence** - Characters and monsters saved to XML files
- **Error Handling** - Comprehensive validation and user-friendly error messages
- **Multiplatform Support** - Works on Windows, Linux, and macOS
- **IRC Protocol** - Full IRC protocol implementation with reconnection logic
- **Logging System** - Configurable logging with different levels

### 🎭 Game Systems

#### Character System (Players)
- **Energy System** - Characters use energy for abilities
- **7 Classes** - Human, Mage, Elf, Dwarf, Orc, Troll, Hobbit
- **Attribute Distribution** - 30 points to distribute among Intelligence, Strength, Dexterity, Endurance, Magic
- **Level System** - Characters can level up to 100
- **Spell System** - Each class has unique spells

#### Monster System (Enemies)
- **Health/Damage/Armor System** - Combat-focused statistics
- **6 Classes** - Werewolf, Vampire, Unicorn, Minotaur, Phoenix, Kraken
- **Instant Creation** - Single command monster creation
- **Special Abilities** - Each monster has unique spells and attributes

### 📁 File Structure
```
/
├── config.lua              # Configuration file
├── main.lua                # Entry point
├── VERSION.md              # Version history
├── modules/
│   ├── character.lua       # Character class
│   ├── character_classes.lua # Character class definitions
│   ├── character_xml.lua   # XML serialization
│   ├── dice.lua            # Dice rolling
│   ├── monster_creation.lua # Monster creation
│   └── irc/
│       └── bot.lua         # IRC bot logic
├── saves/                  # Character saves
└── saves/monster/          # Monster saves
```

### 🔄 Breaking Changes from Previous Versions
- **Removed French commands** - Only English commands work now
- **Removed old command names** - !listjoueur, !getjoueur, !createjoueur, !recap, !salut no longer work
- **Configuration required** - config.lua must be present with valid settings

### 🐛 Bug Fixes
- Fixed character creation state management
- Fixed monster creation validation
- Fixed XML parsing and saving
- Fixed IRC reconnection logic
- Fixed multiplatform directory handling

### 📈 Performance Improvements
- Faster character loading
- Optimized XML parsing
- Reduced memory usage
- Better error recovery

### 🎯 Future Roadmap
- **Version 0.4.0** - Combat system and PVP
- **Version 0.5.0** - Quest system and NPCs
- **Version 0.6.0** - Guild system and parties
- **Version 1.0.0** - Full RPG game with persistence

## Version 0.2.0
**Release Date:** 2024

### Features
- Basic character creation
- Monster creation
- IRC bot framework
- XML saving/loading
- French/English mixed interface

## Version 0.1.0
**Release Date:** 2024

### Features
- Initial prototype
- Basic IRC connectivity
- Character class structure
- French interface

---

**RPG IRC Bot** - Bring your tabletop RPG adventures to IRC!
**License:** MIT
**Author:** Major-GHZ
**Repository:** https://github.com/Major-GHZ/rpg-irc-bot