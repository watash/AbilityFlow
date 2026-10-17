# AbilityFlow

**A boss timeline that lights up when it matters.**

Midnight shows upcoming boss abilities on a timeline bar. AbilityFlow replaces that bar with its own, in a look you control, from the icons and their names to how they light up in the last seconds. It shows more, too: breaks, ready checks and pull countdowns, reminders from Northern Sky Raid Tools, and timers from BigWigs and DBM.

Pick the game's look or a cleaner one when you first log in, and fine-tune it later, or never.

## Features

### The bar

- Vertical or horizontal, running either way, any length and thickness
- Abilities wait beside the bar, slide onto it as they come near, queue up and pause just like the game's own
- Time marks every 5 or 10 seconds, as lines, icons or text
- The standard background, or a plain one with your own texture, color and border
- Placed in Edit Mode, with its own size and position for each Edit Mode layout

### How abilities look

- A live preview: click any part of the sample icon to edit it
- Icon size and zoom, border (the game's frame, a flat color, or colored by debuff type)
- Spell name and countdown: font, size, outline, color, position, an optional background
- Name, countdown and border can take the color of the event: its debuff type, its color in a boss mod, or the color of an NSRT note or alert
- Debuff, danger and role indicators, each with its own size and place

### Appearance by timer

- Change how an ability looks as it comes close: up to 7 templates on the last 12 seconds
- Countdown color and size, tenths of a second
- Glows (several types, each with its own size, speed, direction and color); the optional [Orbit: Media](https://github.com/MoONSHO7/Orbit-Media) pack adds dozens more
- Pulse and flash, like the game's highlight, at any strength

### More on the bar

- Ready check and pull countdown, with who started them in their class color
- Break timers, whatever starts them, even with no boss mod installed
- (optional) Reminders from Northern Sky Raid Tools, in colors of their own
- (optional) Ability names from BigWigs or DBM, with counts and your renames
- (optional) Timers the game does not have, from BigWigs (stages, bars started by players) or DBM
- (optional) Ability colors from BigWigs or DBM

### Profiles

- One per character, or one for each specialization
- Share a profile as a line of text

## Requirements

The game's boss warnings must be on: Options > Gameplay Enhancements > Enable Boss Warnings. The game's own bar is hidden by default; you can show it again in the addon's settings.

## Installation

Install it from CurseForge, Wago or WoWInterface, or download the archive of a version from [Releases](https://github.com/watash/AbilityFlow/releases) and unpack it into `World of Warcraft/_retail_/Interface/AddOns`, so that the folder `AbilityFlow` is there.

## Commands

- `/aflow` does the same as `/abflow` everywhere below.
- `/abflow` opens the settings window (it closes it when it is open); `/abflow settings` does the same.
- `/abflow test [seconds]` adds a sample ability that lasts that many seconds (a few of different lengths when no number is given); `/abflow test pause` pauses the samples and `/abflow test clear` removes them.
- `/abflow help`, or any other word, lists the commands.

The settings window also opens from the addon menu by the minimap, and from "All Settings" in the bar's Edit Mode dialog.

## Works with

AbilityFlow reads, and never changes, what these addons share:

- [BigWigs](https://github.com/BigWigsMods/BigWigs): breaks, the names of boss abilities and its own timers
- [Deadly Boss Mods](https://github.com/DeadlyBossMods/DeadlyBossMods): breaks, the names of boss abilities and its own timers
- [Northern Sky Raid Tools](https://www.curseforge.com/wow/addons/northern-sky-raid-tools): reminders
- [Orbit: Media](https://github.com/MoONSHO7/Orbit-Media): optional, more glows to choose from

## Libraries

Included, unchanged, in `Libs/`:

- [LibStub](https://www.wowace.com/projects/libstub) (public domain)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0)
- [LibEditMode](https://github.com/p3lim-wow/LibEditMode)
- [LibOrbitGlow-1.0](https://github.com/MoONSHO7/Orbit-Libs) (MIT), by MoONSHO7

Each library keeps its own licence and notices.
