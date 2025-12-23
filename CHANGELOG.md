# Original Project

- This is a fork of the original [streamdeck-starcitizen](https://github.com/mhwlng/streamdeck-starcitizen) by mhwlng.
- The original project was created by [mhwlng](https://github.com/mhwlng) and is licensed under the MIT License.

## Changelog

### Added
- **RSI Launcher Auto-Detection**: The plugin now automatically reads the RSI Launcher configuration files from `%APPDATA%\rsilauncher\` to find your Star Citizen installation path
  - Reads `library_folder.json` for the game library location
  - Reads `settings.json` for installation directories
  - Parses launcher log files as a fallback


- **Currently only available for the Static Button:**
  - **Search Functionality**: Added a search box to find Keybindings faster in the dropdown list
  - **Dynamic Function Loading**: Functions are now loaded dynamically via WebSocket communication instead of hardcoded HTML Option Values

### Technical Changes
- `Static.cs`: Added SDK event handlers (`OnPropertyInspectorDidAppear`, `OnSendToPlugin`) for proper Property Inspector communication
- `Static.html` / `statictemplate.html`: Implemented dynamic dropdown population via JSON WebSocket messages
- `SCPath.cs`: Added `FindInstallationFromRSILauncher()` method and improved `IsValidStarCitizenInstallation()` to support multiple directory structures
- `DProfileReader.cs`: Simplified `CreateStaticHtml()` to just copy template (dropdown now populated dynamically)






