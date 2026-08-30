# RothRaidManager code index

| File | Responsibility |
|---|---|
| `RothRaidManager.toc` | Retail 12.1 metadata, SavedVariables, and definitive load order |
| `core.lua` | Defaults/sanitization, panel and button creation, secure macro attributes, out-of-combat utility routing, visibility state driver, placement/slash behavior, and combat-deferred apply |
| `options.lua` | Current Blizzard vertical Settings category and refresh callbacks |
| `tests/test_protected_actions.lua` | Mocked regression for secure marker/pull macros, protected utility rejection in combat, deferred state-driver/geometry apply, and drag gating |

Detailed ownership and protected-action routing are in [`ARCHITECTURE.md`](ARCHITECTURE.md) and [`AGENT_GUIDE.md`](AGENT_GUIDE.md).
