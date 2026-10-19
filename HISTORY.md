# AbilityFlow: all changes

Every version, the newest first. Write the notes of a new version at the top, then run `python Tools/release.py X.Y.Z --notes`, which makes CHANGELOG.md (the notes of that version only, which the release and the sites show) from its section here.

## 1.0.2

- The border is colored by the debuff type again.
- Timers of BigWigs and DBM now follow the time limit too.
- The glow now grows with the icon when it disappears.

## 1.0.1

- Fixed an error that sometimes appeared in combat.
- Small optimizations.
- Small improvements to the interface texts.

## 1.0.0

First release.

- A bar for the boss abilities of the game's encounter timeline, vertical or horizontal, in either direction. Placed and sized in Edit Mode, separately for each Edit Mode layout.
- Abilities wait beside the bar while they are far off, slide onto it as they near, queue up, and show the game's pause and queue states.
- Choose between the game's own look and a cleaner one on your first login.
- A settings window with a live preview: the icon, its border, the name, the countdown, and the debuff, danger and role marks can each be changed.
- Appearance by timer: templates set on any of the last 12 seconds change the countdown, glow, pulse and flash as an ability comes closer.
- Profiles, one per character or per specialization, shared as a line of text.
- Ready checks, pull countdowns and breaks on the bar.
- Optional support for BigWigs and DBM (ability names, colors, extra timers) and Northern Sky Raid Tools (reminders and alerts).
