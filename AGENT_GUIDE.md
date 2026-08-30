# RothRaidManager agent guide

## Contract

Target Retail 12.1 / Interface `120100`. Preserve the compact raid utility panel, all secure world-marker/pull macros, ordinary raid/group utilities, state-driver visibility, Settings, movement, and persistence.

Read:

1. `RothRaidManager.toc`
2. `core.lua`
3. `options.lua`
4. `ARCHITECTURE.md`
5. `tests/test_protected_actions.lua`
6. `tests/test_combat_initialization.lua`
7. `Docs/TODO.md`

## Secure initialization

Never create `SecureHandlerStateTemplate` / `SecureActionButtonTemplate` frames or assign attributes during combat. `PLAYER_LOGIN` must defer the whole secure graph when loaded in combat. `PLAYER_REGEN_ENABLED` performs one initialization.

The fixed secure attributes are:

```text
type=macro  macrotext=/wm N
type=macro  macrotext=/cwm N
type=macro  macrotext=/pull 10
```

Do not change them after `CreateUI`. Do not replace them with Lua calls or secure `_onclick` geometry snippets.

## Ordinary utilities

Clear-all, role check, ready check, party/raid conversions, and stopwatch pass through `RunOutOfCombat`. The boundary:

- rejects combat clicks immediately;
- resolves the Blizzard global at click time;
- fails closed when missing/failing;
- never stores or replays an action after combat.

A delayed raid-management command violates user intent.

## Apply ownership

`Apply` alone owns:

- point and offsets;
- scale;
- expanded width/alpha;
- mouse state;
- visibility-driver registration.

Combat-time changes set one `pendingApply`; regen applies the current DB once. Never mutate parent, points, size, scale, alpha, mouse state, driver, or secure attributes in combat.

## SavedVariables

Schema and validation live in `core.lua`. Allow only the nine standard anchor strings and bounded offsets. Access-check external/event/slash values before type, comparison, formatting, indexing, or persistence.

## Visibility and movement

Keep the canonical state driver:

```text
[group:party][group:raid] show; hide
```

Do not poll group state. Drag requires unlocked, out of combat, ALT, and optionally CTRL. Reset and expansion/collapse are blocked in combat.

## Non-ownership

Do not disable or claim ownership of Blizzard CUF/compact raid frames. Do not print that they were disabled. Do not inspect roster/permission state to emulate Blizzard action enforcement.

## Verification

```text
texlua --luaconly core.lua options.lua tests/test_protected_actions.lua tests/test_combat_initialization.lua
texlua tests/test_protected_actions.lua
texlua tests/test_combat_initialization.lua
```

Static policy must exclude:

```text
SecureHandlerClickTemplate
_onclick
DisableAddOn
InterfaceOptionsCheckButtonTemplate
OptionsSliderTemplate
InterfaceOptions_AddCategory
C_Timer.NewTicker
COMBAT_LOG_EVENT_UNFILTERED
```

Then complete `Docs/TODO.md` on the exact client build. Mock success does not prove live permissions, taint, secure macro execution, or visuals.

Do not add GitHub Actions or other CI unless the repository owner explicitly changes that policy.
