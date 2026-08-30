# RothRaidManager architecture

## Ownership

`core.lua` owns SavedVariables validation, secure button construction, the group visibility state driver, ordinary utility-action gates, panel geometry, movement, slash commands, and combat deferral. `options.lua` writes the same validated top-level settings and requests the single core apply boundary.

Blizzard remains the authority for group membership, raid permissions, marker execution, ready/role checks, party/raid conversion, stopwatch behavior, and protected-action enforcement.

## Initialization boundary

The event frame may load during combat, but no secure manager/button is created and no secure attribute is written while `InCombatLockdown()` is true. `PLAYER_LOGIN` records one `pendingInitialize` flag. `PLAYER_REGEN_ENABLED` creates the complete secure graph once, assigns fixed macro attributes, registers the visibility state driver, and clears the flag.

This prevents `/reload` in combat from attempting secure frame creation or `SetAttribute` calls.

## Button classes

### Secure declarative buttons

The 16 world-marker buttons and the pull button use `SecureActionButtonTemplate` with attributes assigned only in `CreateUI`:

```text
/wm 1..8
/cwm 1..8
/pull 10
```

No later `Apply`, Settings callback, combat transition, or slash command mutates those attributes.

### Ordinary utilities

Clear-all, role check, convert-to-party, ready check, convert-to-raid, and stopwatch are ordinary buttons routed through `RunOutOfCombat`. A combat click is rejected immediately and never queued for regen. Missing/failing Blizzard APIs fail closed.

## Panel lifecycle

The manager uses `SecureHandlerStateTemplate,BackdropTemplate`; Blizzard's state driver owns party/raid visibility:

```text
[group:party][group:raid] show; hide
```

`Apply` is the sole owner of point, scale, expanded width/alpha, mouse state, and state-driver registration. Combat-time requests set one `pendingApply`; regen applies the latest SavedVariables state once.

Dragging and reset are blocked in combat. Persisted anchor names are restricted to the nine valid WoW points and offsets are bounded. Corrupt or inaccessible values fall back to the left-edge default before `SetPoint`.

## State

Schema v2 persists only enablement, lock, scale, drag modifier, expanded state, and bounded position. Secure frame references, button registry, pending flags, and message throttle remain runtime-only.

## Explicit non-ownership

The addon does not disable or modify Blizzard compact raid frames/CUF profiles. It does not own roster state, permissions, ready/role state, or marker state.

## Performance

There is no polling, `OnUpdate`, ticker, combat log, roster scan, or delayed command queue. Work occurs only during initialization, Settings/slash changes, dragging, and combat regen application.

## Evidence boundary

Local mocks verify secure macro attributes, combat-load deferral, fail-closed utility actions, anchor sanitization, immutable attributes, and one post-combat apply. Live permissions, secure macro execution, state-driver behavior, taint, and visual layout remain client tests.
