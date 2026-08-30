# RothRaidManager

Compact raid utility panel for World of Warcraft Retail 12.1. It provides secure world-marker and pull macros plus explicitly out-of-combat raid/group utility controls.

## Compatibility

- Retail / Midnight `12.1.0`
- Interface `120100`
- Version `0.4.0`
- Verified Blizzard source baseline `12.1.0.69497`
- SavedVariables `RothRaidManagerDB` schema v2
- External dependencies: none
- GitHub Actions / CI: none

## Actions

Secure declarative buttons:

- place world markers 1–8 with `/wm N`;
- clear world markers 1–8 with `/cwm N`;
- run `/pull 10`.

Ordinary out-of-combat buttons:

- clear all markers;
- role check;
- ready check;
- raid-to-party and party-to-raid conversion;
- stopwatch toggle.

Combat clicks on ordinary utilities fail immediately and are never replayed after combat.

## Secure lifecycle

The panel uses `SecureHandlerStateTemplate`; its marker/pull buttons use `SecureActionButtonTemplate`. All secure frames and fixed macro attributes are created only outside combat.

When the addon loads or `/reload` occurs during combat, initialization is deferred as one unit. `PLAYER_REGEN_ENABLED` creates the secure graph once and applies the latest settings. Later Settings/slash changes similarly defer only panel geometry/state-driver application; secure attributes remain immutable.

Blizzard's state driver owns visibility:

```text
[group:party][group:raid] show; hide
```

The addon does not disable or modify Blizzard raid frames.

## Commands

```text
/rrm lock
/rrm unlock
/rrm toggle
/rrm reset
/rrm expand
/rrm collapse
/rrm config
```

Dragging requires unlock, out-of-combat state, ALT, and optionally CTRL. Reset and expansion/collapse are blocked in combat. Saved anchor names and offsets are validated before `SetPoint`.

## Performance

No polling, `OnUpdate`, ticker, combat log, group scan, or delayed utility queue is used.

## Validation

Local Lua 5.1-compatible tests cover:

- all secure marker and pull macro attributes;
- ordinary utility rejection in combat and execution out of combat;
- no replay after combat;
- complete secure initialization deferral for combat reloads;
- immutable attributes after initialization;
- anchor sanitization;
- one deferred panel/state-driver apply;
- movement/reset gates.

Live-client verification remains required; see [Docs/TODO.md](Docs/TODO.md).

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
