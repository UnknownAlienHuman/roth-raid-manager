# RothRaidManager architecture

`Manager.xml` loads `core.lua`. The core initializes `RothRaidManagerDB`, creates the panel and secure utility buttons, applies saved geometry and handles the panel's runtime behavior. `options.lua` owns settings controls and delegates changes back to the core frame.

Because the panel uses `SecureActionButtonTemplate`, future changes must preserve protected-action boundaries and avoid changing secure attributes during combat.
