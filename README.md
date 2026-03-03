# Pinta World Quests

A world quest tracker for World of Warcraft retail. Shows active world quests with time remaining, reward icons, and quality colours — both as a standalone list frame and as an overlay on the world map.

## Features

- **Quest list** — scrollable list of all active world quests, sortable by zone or time remaining. Minimises to a compact header showing the quest count and time range.
- **Map overlay** — panel on the world map showing quests for the current zone. Verbose mode shows icon, title, slot, and time remaining. Compact mode shows a narrow icon + time strip.
- **Expansion filter** — switch between Auto (detects your current expansion), The War Within, Dragonflight, or Midnight.
- **Reward info** — reward icon, quality colour stripe, and item slot shown per quest row.
- **Hover to highlight** — hovering a quest in any list highlights the pin on the world map.
- **Click to navigate** — clicking a quest row opens the world map to that quest's zone.
- **Tooltips** — hover any quest row for reward details. Enable extended tooltips in settings for objectives, item stats, and XP.

## Usage

| Command | Action |
|---|---|
| `/pwq` | Show available commands |
| `/pwq toggle` | Show or hide the quest list |
| `/pwq reset` | Reset all settings to defaults (with confirmation) |

The quest list and map overlay headers have buttons to open settings (⚙), toggle the quest list (WQ), toggle compact map mode (C), and filter by expansion.

## Options

Open via the in-game **Settings → AddOns → Pinta World Quests** panel, or click the ⚙ button in any panel header.

- **Compact map overlay** — switch the map overlay to a narrow icon + time strip (no title or slot info)
- **Extended tooltips** — show quest objectives, item stats, and XP on hover
- **List scale** — resize the quest list frame (50–150%)
- **Background opacity** — adjust the quest list background transparency
- **Show on right side of map** — anchor the map overlay to the right edge of the map instead of the left
- **Show Debug Messages** — print scan and cache activity to chat
