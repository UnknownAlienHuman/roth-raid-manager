# RothRaidManager agent guide

## Start here

Read [`RothRaidManager.toc`](RothRaidManager.toc): it loads `Manager.xml` (which includes `core.lua`) and then `options.lua`. `core.lua` creates the global frame named from the addon var (`RothRaidManager`), while `options.lua` finds that frame via `_G["RothRaidManager"]`.

## Runtime and state flow

At file load, `core.lua` merges defaults into `RothRaidManagerDB`, creates the manager panel, applies the persisted point/scale/visibility, creates world-marker/role/ready-check/party-raid/pull/stopwatch buttons, and registers the secure state-frame toggle. The manager listens to `PLAYER_LOGIN`; the current handler only reports Blizzard compact-frame state because `needReload` is hard-coded false in this tree. Do not document this version as actively disabling Blizzard raid-frame addons.

The panel's buttons include `SecureActionButtonTemplate`; marker/pull buttons receive macro attributes (`/wm`, `/cwm`, `/pull`) at creation. `RegisterStateDriver(manager, "visibility", "[group:party][group:raid] show; hide")` controls group visibility. Slash `/rrm lock|unlock|toggle|reset` updates DB and frame state. `options.lua` registers a Canvas Settings category and delegates checkbox/slider/button actions to the slash handler/core frame.

## State, dependencies, risks

The single SavedVariables root is `RothRaidManagerDB`: `enabled`, `locked`, `scale`, `ctrlAltDrag`, and `pos`. There are no addon dependencies beyond Blizzard templates/APIs. The persisted position is written on drag stop; reset restores the left-edge default.

The secure panel and macro attributes are the critical protected-action boundary. Do not set secure attributes, change frame parent/anchors, or mutate state-driver inputs in combat. The slash handler currently changes `locked`, `enabled`, and points without an explicit combat gate; if adding protected operations, queue them and apply after `PLAYER_REGEN_ENABLED`. Keep marker/role/ready-check APIs as button click behavior rather than polling.

## Change routing

- DB/defaults, panel/buttons, secure attributes, state driver, `/rrm`: `core.lua`.
- Settings controls and bridge callbacks: `options.lua`.
- XML/load order: `Manager.xml` and TOC only; update docs if the include contract changes.

## Verification

Static: verify XML/TOC references, parse `core.lua` and `options.lua`, and run `git diff --check`. In game, test `/rrm lock|unlock|toggle|reset`, ALT/CTRL+ALT dragging, party/raid visibility, each marker/cancel/role/ready-check/pull/stopwatch button, Settings writes, reload persistence, and combat lockdown. Confirm no protected-action errors and explicitly check whether Blizzard raid frames are merely reported or actually disabled. Current audit is not a live client run.
