# Version 1.2.0 - RPG IRC Bot

## Release Notes

### New Features
- **Character Creation**: Players can now create characters with `!createjoueur` command
- **Monster Creation**: Monsters can be created with `!createmonster` command
- **Dice Rolling**: Added `!roll` command for dice rolling
- **Character Listing**: `!listjoueur` lists all saved characters
- **Monster Listing**: `!listmonsters` lists all created monsters

### Improvements
- **English Comments**: All code is now commented in English
- **Error Handling**: Improved error messages and validation
- **Code Cleanup**: Removed unused files and test files
- **Documentation**: Added detailed comments for all functions

### Bug Fixes
- Fixed character creation flow
- Fixed monster creation with proper classes
- Fixed dice rolling command
- Fixed character listing command

### Issues Resolved
- Character creation now works properly
- Monster creation uses correct classes
- Dice rolling command works as expected
- Character listing shows proper details

### Files Modified
- `main.lua`: Entry point with character creation test
- `modules/irc/bot.lua`: Main IRC bot logic
- `modules/character.lua`: Character management
- `modules/monster_creation.lua`: Monster creation
- Removed unused test files and backups

### How to Use
1. Launch the bot: `lua main.lua`
2. Connect to IRC server
3. Use commands:
   - `!createjoueur` to create a player character
   - `!createmonster <name> <class> <level>` to create a monster
   - `!roll <number>` to roll dice
   - `!listjoueur` to list characters
   - `!listmonsters` to list monsters

### Next Steps
- Add more monster classes
- Add more character classes
- Add combat system
- Add quest system

## Version History
- 1.0.0: Initial release
- 1.1.0: Added monster creation
- 1.2.0: Current version with full English comments and cleanup