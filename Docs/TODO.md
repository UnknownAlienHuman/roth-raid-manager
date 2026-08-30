# RothRaidManager live validation matrix

Local tests establish code boundaries only. Complete these checks on the exact Retail 12.1 client before release.

## P0 — initialization and persistence

- [ ] Fresh install outside combat.
- [ ] `/reload` while in combat: no forbidden/secure-creation error; panel appears once after combat.
- [ ] Migration from representative pre-0.4 SavedVariables.
- [ ] Corrupt point/relative-point/scale/offset values fall back safely.
- [ ] Settings and position persist through `/reload`, logout, and restart.

## P0 — secure actions

- [ ] Place world markers 1–8 with raid leader/assistant permissions.
- [ ] Clear world markers 1–8.
- [ ] Verify non-privileged behavior fails through Blizzard without addon errors.
- [ ] `/pull 10` with and without a pull-timer provider.
- [ ] Confirm secure attributes remain unchanged after Settings changes, combat transitions, expand/collapse, and reload.

## P0 — ordinary utilities

- [ ] Clear all markers outside combat.
- [ ] Role check outside combat.
- [ ] Ready check outside combat.
- [ ] Raid-to-party and party-to-raid conversions outside combat.
- [ ] Stopwatch toggle outside combat.
- [ ] Click each utility during combat; confirm immediate rejection and no execution after combat.
- [ ] Missing/unavailable Blizzard utility API fails closed.

## P0 — panel lifecycle

- [ ] Hidden solo; shown in party and raid through the state driver.
- [ ] Enable/disable while in and out of combat.
- [ ] Lock/unlock and ALT / CTRL+ALT drag policy.
- [ ] Expand/collapse width and alpha.
- [ ] Reset out of combat and rejection in combat.
- [ ] Change scale, lock, expanded, and enabled state during combat; one final state applies after regen.
- [ ] Repeated Settings changes do not duplicate buttons or state drivers.
- [ ] Blizzard CUF/compact raid frames remain enabled and unmodified.

## P1 — safety and performance

- [ ] `/console taintLog 1` plus Lua error capture.
- [ ] No blocked, forbidden, protected-action, or secret-value error attributable to the addon.
- [ ] CPU/allocation capture solo, party, raid, and during repeated Settings changes.
- [ ] Confirm no polling, `OnUpdate`, ticker, combat log, or delayed utility queue.

## Release gate

Record exact client build, group role/permissions, each action result, combat-reload result, taint/error logs, and profiler data before publishing.
