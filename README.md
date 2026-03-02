# Pinta World Quests

A world quest tracker for World of Warcraft retail. Shows active world quests with time remaining, reward icons, and quality colours — both as a standalone list frame and as an overlay on the world map.

## Features

- **Quest list** — scrollable list of all active world quests, sortable by zone or time remaining. Minimises to a compact header showing the quest count and time range.
- **Map overlay** — panel that appears on the world map showing quests for the current zone. Compact or verbose mode (with gear slot / item category info).
- **Expansion filter** — switch between Auto (detects your current expansion), The War Within, Dragonflight, or Midnight.
- **Reward info** — reward icon, quality colour stripe, and item slot shown per quest.
- **Hover to highlight** — hovering a quest in any list highlights the pin on the world map.

## Usage

| Command | Action |
|---|---|
| `/pwq` | Show available commands |
| `/pwq toggle` | Show or hide the quest list |
| `/pwq reset` | Reset all settings to defaults (with confirmation) |

The quest list and map overlay also have buttons in their headers to open settings, toggle the list, and filter by expansion.

## Options

Open via the in-game **Settings → AddOns → Pinta World Quests** panel, or click the ⚙ button in any panel header.

- **Compact map overlay** — hide slot/category info on the map overlay for a narrower panel
- **List scale** — resize the quest list frame (50–150%)
- **Background opacity** — adjust the quest list background transparency
- **In-map quest list side** — anchor the map overlay to the left or right of the map
- **Show Debug Messages** — print scan and cache activity to chat

## Notes

This is an early release. Expansion zone IDs are defined in `src/worldquests.lua` — if world quests from a specific zone are missing, the map IDs for that zone may need to be added.
