# RPG IRC Bot 🎮🤖

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-blue.svg)](VERSION.md)

**Bring your tabletop RPG adventures to IRC!**

## 📖 About

RPG IRC Bot is a powerful IRC bot that brings tabletop RPG mechanics to your favorite IRC channel. Create characters, battle monsters, roll dice, and manage your RPG adventures - all through IRC commands!

## 🚀 Features

### 🎭 Character System
- **7 Playable Classes**: Human, Mage, Elf, Dwarf, Orc, Troll, Hobbit
- **Energy System**: Characters use energy for abilities
- **Attribute Distribution**: 30 points to distribute among Intelligence, Strength, Dexterity, Endurance, Magic
- **Level System**: Characters can level up to 100
- **Unique Spells**: Each class has special abilities

### 👹 Monster System
- **6 Monster Classes**: Werewolf, Vampire, Unicorn, Minotaur, Phoenix, Kraken
- **Health/Damage/Armor**: Combat-focused statistics
- **Instant Creation**: Single command monster creation
- **Special Abilities**: Each monster has unique powers

### 🎲 Game Commands

#### Character Commands
- `!createplayer` - Start interactive character creation
- `!listplayer` - List all saved characters
- `!getplayer <name>` - Load a specific character
- `!stats` - Show your character's statistics

#### Monster Commands
- `!createmonster <name> <class> <level>` - Create a monster
- `!listmonsters` - List all created monsters

#### Utility Commands
- `!roll <number>` - Roll dice (1-10 dice)
- `!hello` - Friendly greeting
- `!ping` - Test bot connection
- `!help` - Show help menu

## 📥 Installation

### Prerequisites
- Lua 5.1 or later
- LuaSocket library
- Lua IRC Engine (included in `lua-irc-engine/` directory)
- LuaFileSystem (optional, for better file handling)
- IRC server connection

### Included Libraries

The project includes these libraries in the repository:

- **Lua IRC Engine** (`lua-irc-engine/`) - IRC protocol implementation
  - Official Repository: [https://github.com/mirrexagon/lua-irc-engine](https://github.com/mirrexagon/lua-irc-engine)
  - License: MIT
  - Already bundled, no separate installation needed

- **LuaSocket** (`luasocket/`) - Networking and socket operations
  - Official Repository: [https://github.com/diegonehab/luasocket](https://github.com/diegonehab/luasocket)
  - License: MIT
  - Included for convenience, can also install via luarocks

### Setup

1. **Clone the repository:**
```bash
git clone https://github.com/Major-GHZ/rpg-irc-bot.git
cd rpg-irc-bot
```

2. **Install dependencies:**
```bash
# Install LuaSocket (required)
luarocks install luasocket

# Install Lua IRC Engine (required, included in repo)
# Official repository: https://github.com/mirrexagon/lua-irc-engine
# Already included in lua-irc-engine/ directory

# Install LuaFileSystem (optional but recommended)
luarocks install luafilesystem
```

3. **Configure the bot:**
Edit `config.lua` to set your IRC server details:
```lua
config.irc = {
    server = "irc.yourserver.com",
    port = 6667,
    nickname = "RPG_Bot_GameMaster",
    default_channel = "#your-channel",
    -- other settings...
}
```

4. **Run the bot:**
```bash
lua main.lua
```

## 🎮 Usage

### Creating a Character

```irc
You: !createplayer
Bot: STEP 1/7: Character name
You: Gandalf
Bot: Choose a class (human/mage/elf/dwarf/orc/troll/hobbit):
You: mage
Bot: You have 30 points to distribute among your attributes.
Bot: Enter value for intelligence (max 30, remaining points: 30):
You: 15
Bot: Enter value for strength (max 15, remaining points: 15):
You: 5
-- Continue through all attributes --
Bot: Enter level (1-100):
You: 20
Bot: Gandalf, your character has been created: Gandalf (Mage, Level 20).
Bot: Use !stats to see your character information at any time.
```

### Creating a Monster

```irc
You: !createmonster DragonNoir phoenix 10
Bot: === MONSTER CREATED SUCCESSFULLY =====
Bot: Your monster is ready for combat!
Bot: MONSTER INFORMATION:
Bot: Name: DragonNoir (Phoenix)
Bot: Level: 10
Bot: Health: 80/80
Bot: Damage: 18
Bot: Armor: 12
Bot: ATTRIBUTES:
Bot: Intelligence: 8, Strength: 6, Dexterity: 6, Endurance: 7, Magic: 9
Bot: SPECIAL SPELLS:
Bot: Fire Rebirth, Ash Cloud, Phoenix Flame
Bot: The monster has been saved successfully!
```

### Rolling Dice

```irc
You: !roll 3
Bot: You rolled 3 dice: [4, 6, 2] = Total: 12
```

## 📁 File Structure

```
/
├── config.lua              # Configuration file
├── main.lua                # Entry point
├── README.md               # This documentation
├── VERSION.md              # Version history
├── modules/
│   ├── character.lua       # Character class
│   ├── character_classes.lua # Character class definitions
│   ├── character_xml.lua   # XML serialization
│   ├── dice.lua            # Dice rolling
│   ├── monster_creation.lua # Monster creation
│   └── irc/
│       └── bot.lua         # IRC bot logic
├── saves/                  # Character saves (auto-created)
└── saves/monster/          # Monster saves (auto-created)
```

## 🔧 Configuration

All bot settings are in `config.lua`:

### IRC Settings
```lua
config.irc = {
    server = "irc.oftc.net",       -- IRC server address
    port = 6667,                   -- IRC server port
    nickname = "RPG_Bot_GameMaster", -- Bot nickname
    default_channel = "#rpg-game", -- Default channel
    reconnect_delay = 10,         -- Reconnect delay in seconds
    connection_timeout = 30,      -- Connection timeout
    receive_timeout = 5,         -- Receive timeout
    ping_interval = 60           -- Keep-alive ping interval
}
```

### Game Settings
```lua
config.game = {
    character_save_dir = "saves/",       -- Character save directory
    monster_save_dir = "saves/monster/", -- Monster save directory
    max_character_name_length = 50,      -- Max character name length
    max_monster_name_length = 50,        -- Max monster name length
    max_level = 100,                     -- Maximum level
    starting_energy = 100,               -- Starting energy
    max_dice_roll = 10                   -- Maximum dice roll
}
```

## 🎯 Character Classes

### Player Classes

| Class | Description | Base Energy |
|-------|-------------|-------------|
| **Human** | Versatile character | 80 |
| **Mage** | Powerful magic user | 100 |
| **Elf** | Fast and precise | 70 |
| **Dwarf** | Robust and resistant | 90 |
| **Orc** | Brutal and resistant | 85 |
| **Troll** | Powerful but slow | 110 |
| **Hobbit** | Agile and stealthy | 60 |

### Monster Classes

| Class | Description | Base Health |
|-------|-------------|-------------|
| **Werewolf** | Fast and powerful | 60 |
| **Vampire** | Immortal with regeneration | 70 |
| **Unicorn** | Magical with healing | 65 |
| **Minotaur** | Powerful and resistant | 90 |
| **Phoenix** | Magical rebirth | 80 |
| **Kraken** | Giant sea monster | 120 |

## 🔄 Character Creation Process

1. **Name**: Choose your character's name
2. **Class**: Select from 7 available classes
3. **Attributes**: Distribute 30 points among:
   - Intelligence
   - Strength
   - Dexterity
   - Endurance
   - Magic
4. **Level**: Choose level (1-100)
5. **Confirmation**: Review and confirm

## 👾 Monster Creation

Monsters are created instantly with a single command:

```irc
!createmonster <name> <class> <level>
```

Example:
```irc
!createmonster AncientDragon phoenix 25
```

## 📊 Statistics Systems

### Characters (Players)
- **Energy**: Used for abilities and spells
- **Attributes**: Intelligence, Strength, Dexterity, Endurance, Magic
- **Level**: 1-100
- **Spells**: Class-specific abilities

### Monsters (Enemies)
- **Health**: Hit points
- **Damage**: Attack power
- **Armor**: Defense rating
- **Attributes**: Intelligence, Strength, Dexterity, Endurance, Magic
- **Level**: 1-100
- **Spells**: Special abilities

## 🛠️ Technical Details

### XML Persistence
- Characters saved as XML files in `saves/`
- Monsters saved as XML files in `saves/monster/`
- Automatic file creation and management

### Error Handling
- Comprehensive input validation
- User-friendly error messages
- Graceful error recovery

### IRC Engine Details
- **Lua IRC Engine** - Full IRC protocol implementation
- **Module System** - Modular IRC functionality (base, message, channel)
- **Event Handling** - Callback-based event system
- **Reconnection Logic** - Automatic reconnection with configurable delays
- **Ping/Pong** - Keep-alive mechanism to maintain connections

### Multiplatform Support
- Works on Windows, Linux, and macOS
- Cross-platform directory handling
- Consistent file operations

## 🐛 Troubleshooting

### Common Issues

**Bot won't connect:**
- Check `config.lua` IRC settings
- Verify server address and port
- Check firewall settings

**Commands not working:**
- Ensure bot has joined the channel
- Check for typos in commands
- Verify bot has proper permissions

**Characters not saving:**
- Check `saves/` directory permissions
- Verify XML file structure
- Check for invalid characters in names

## 📈 Performance

- **Fast character loading**: Instant access to saved characters
- **Optimized XML parsing**: Efficient file operations
- **Low memory usage**: Minimal resource consumption
- **Stable connections**: Automatic reconnection logic

## 🎨 Customization

### Adding New Classes
Edit `modules/character_classes.lua`:
```lua
-- Add new character class
new_class = {
    name = "Paladin",
    description = "Holy warrior with healing abilities",
    base_attributes = {
        intelligence = 4,
        strength = 8,
        dexterity = 5,
        endurance = 7,
        magic = 6
    },
    base_spells = {"Holy Strike", "Divine Healing", "Blessing"},
    base_energy = 90,
    base_energy_max = 90
}
```

### Modifying Configuration
Edit `config.lua` to change any setting:
```lua
-- Change maximum level
config.game.max_level = 200

-- Change bot nickname
config.irc.nickname = "MyCustomBotName"

-- Change default channel
config.irc.default_channel = "#my-channel"
```

## 📚 Examples

### Character Creation
```irc
User: !createplayer
Bot: STEP 1/7: Character name
User: Aragorn
Bot: Choose a class (human/mage/elf/dwarf/orc/troll/hobbit):
User: human
Bot: You have 30 points to distribute...
-- Continue through creation process --
Bot: Aragorn, your character has been created!
```

### Monster Creation
```irc
User: !createmonster Balrog demon 50
Bot: === MONSTER CREATED SUCCESSFULLY =====
Bot: Name: Balrog (Demon)
Bot: Level: 50
Bot: Health: 200/200
Bot: Damage: 45
Bot: Armor: 30
```

### Loading Character
```irc
User: !listplayer
Bot: Here is the list of saved characters (2):
Bot: • Aragorn (Human, Level 20) - Energy: 80/80
Bot: • Gandalf (Mage, Level 25) - Energy: 100/100
User: !getplayer Gandalf
Bot: The character 'Gandalf' has been loaded successfully!
User: !stats
Bot: Gandalf, character recap: Gandalf (Mage, Level 25).
Bot: Attributes: Int=15, Str=5, Dex=8, End=7, Mag=10.
Bot: Spells: Fireball, Lightning, Magic Shield.
Bot: Energy: 100/100
```

## 📖 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

### Key GPLv3 Terms:
- **Free to use, modify, and distribute**
- **Source code must be made available** when distributing modified versions
- **Copyleft provisions** apply to derivative works
- **No warranty** provided

## 🤝 Contributing

Contributions are welcome! By contributing to this project, you agree to license your contributions under GPLv3.

### Contribution Guidelines:

1. **Fork the repository**
2. **Create your feature branch**: `git checkout -b feature/AmazingFeature`
3. **Commit your changes**: `git commit -m 'Add some AmazingFeature'`
4. **Push to the branch**: `git push origin feature/AmazingFeature`
5. **Open a Pull Request**

### Code Standards:
- Follow existing code style
- Write clear, documented code
- Include tests where applicable
- Respect GPLv3 licensing

## 🙏 Acknowledgments

- **Lua community** for the excellent language
- **IRC protocol developers** for the foundation
- **All contributors and testers** for their valuable input
- **Tabletop RPG enthusiasts** for inspiration
- **Free Software Foundation** for GPLv3

## 📬 Contact

For questions, suggestions, or support:
- **GitHub Issues**: https://github.com/Major-GHZ/rpg-irc-bot/issues
- **Repository**: https://github.com/Major-GHZ/rpg-irc-bot

## 📰 Changelog

See [VERSION.md](VERSION.md) for detailed version history and changes.

---

**RPG IRC Bot** - Transform your IRC channel into an epic RPG adventure! 🎮✨

*Version 0.3.0 | GNU GPLv3 License | © 2024 Major-GHZ*

*Bringing the spirit of tabletop RPGs to the digital world, one IRC channel at a time.*