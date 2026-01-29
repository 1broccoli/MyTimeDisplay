# MyTimeDisplay - Complete Feature Set

## Version Information
- **Current Version:** 1.3
- **Supported Clients:** WoW Classic (11403), TBC (20504), Retail (110000)
- **Framework:** ACE3 (Ace3.lua)

## Core Features

### Display Options
- **Show Local Time** - Display your local computer time in 24-hour or 12-hour format
- **Show Server Time** - Display the WoW game server time in 24-hour or 12-hour format  
- **Show Date Info** - Display the current date with day name and month information
- **Use 12-Hour Format** - Toggle between 24-hour (00:00) and 12-hour (12:00 AM/PM) time display
- **Show Backdrop** - Toggle the display background border on/off

### Appearance Options
- **Background Opacity** - Adjust the transparency of the display background (0-100%)
- **Font Selection** - Choose from 4 WoW game fonts:
  - Game Font Highlight (default)
  - Game Font Normal
  - Game Font White
  - Game Font White Small
- **Font Outline** - Choose outline style:
  - Outline (default)
  - Thick Outline
  - None
- **Frame Scale** - Adjust the size of the entire time display (0.5x to 2.0x)

### Profile Management
- **Per-Character Profiles** - Save separate settings for each character
- **Account-Wide Settings** - Option to share settings across all characters
- **Class-Specific Profiles** - Save profiles specific to character class
- **Reset to Defaults** - Quickly reset all settings to factory defaults

## Advanced Features

### Smart Layout
- **Dynamic Frame Sizing** - Frame automatically adjusts size based on enabled display options
- **No Dead Space** - Display intelligently filters out empty lines for compact presentation

### Customization
- **Draggable Frame** - Click and drag the display to reposition it anywhere on screen
- **Persistent Positioning** - Frame position is saved and restored with your settings
- **Color Coding** - Local time (green), Server time (gold), Date (multi-color by month)
- **Day Suffixes** - Proper ordinal suffixes (st, nd, rd, th) for dates

### Interface
- **Right-Click Settings** - Right-click the display frame to open the settings panel
- **Chat Commands** - Use `/mytd config` or `/mytdconfig` to open settings
- **Tooltip** - Hover over the display to see current full date and time

## Technical Implementation

### Database
- Uses AceDB-3.0 for persistent per-character storage
- Database file: MyTimeDisplayDB (WTF/Account/*/SavedVariables/)
- Automatic backup and version management

### Dependencies
- LibStub (library stub)
- CallbackHandler-1.0 (event system)
- AceAddon-3.0 (addon lifecycle)
- AceEvent-3.0 (event handling)
- AceDB-3.0 (database)
- AceConfig-3.0 (configuration UI)
- AceGUI-3.0 (GUI components)
- AceConsole-3.0 (chat commands)

### Optional Enhancements
- WeakAuras (for potential integration)
- Details! (for potential integration)

## Commands

### Chat Commands
- `/mytd` - Open settings window
- `/mytd config` - Open settings window
- `/mytdconfig` - Open settings window
- `/mytd help` - Display help message

### In-Game Interaction
- **Right-Click** - Open settings window
- **Left-Click** - Can be dragged to reposition
- **Hover** - Display tooltip with full date and time

## Settings Location
- **Main Settings:** System menu → AddOns → MyTimeDisplay
- **Character-Specific:** Per-character profile saves all display and appearance settings
- **Database File:** WTF/Account/[Account]/SavedVariables/MyTimeDisplayDB.lua

## Tips & Tricks

1. **Minimize Clutter** - Disable options you don't need (e.g., if you only want server time, disable local time and date)
2. **Scale & Position** - Use Frame Scale slider to resize, then reposition with drag
3. **Multiple Profiles** - Create different profiles for different play styles (PvP, Raids, etc.)
4. **Font Matching** - Choose the same font outline as other UI addons for visual consistency
5. **Quick Access** - `/mytd` is faster than navigating through menus

## Troubleshooting

### Settings not saving?
- Check that SavedVariables folder has write permissions
- Disable conflicting addons and reload UI

### Display not appearing?
- Make sure at least one display option is enabled (Local Time, Server Time, or Date)
- Try `/mytd config` and verify opacity is above 0%

### Font looks wrong?
- Try changing Font Outline setting (None, Outline, or Thick Outline)
- Ensure your UI scale matches the Frame Scale setting

### Position reset after logout?
- Frame position is saved only when settings are applied
- Right-click to open settings after repositioning to save

## Version History

### v1.3 (Current)
- Added per-character profile support with AceDB
- Implemented AceConfig-based settings UI
- Added profile management (character/account-wide)
- Added Frame Scale slider
- Implemented Reset to Defaults button
- Dynamic frame sizing eliminates dead space
- Fixed checkbox state persistence

### v1.2
- Added font selection and outline options
- Added frame opacity control
- Implemented ACE3 library integration

### v1.1
- Initial ACE3 framework migration
- Per-character database support

### v1.0
- Initial release with manual addon management
