# Troubleshooting

## No G prompt

Check dependencies/resource state, selected character and configured entrance. Check F8/server errors. Stop duplicate stable implementations. Try `/stables` at the entrance.

## StableLocale / StableInteractions is nil

After manifest changes, run **refresh**, then **restart vorp_stables** in the server console. New files must be deployed, not just saved in your editor. Reconnect if the client still has an old resource pack. Read preceding load errors; do not hide missing files by deleting dependent code.

## Lead / Dismiss missing

Call your selected horse/wagon using H/J. Target your own entity with the right mouse button. Lead belongs to the riding horse. Dismiss applies to the wagon, including its draft horse. Draft leading defaults off. Another player's ride should not show your private actions.

RedM hides prompts when their associated control is disabled. The stable leaves E/F enabled; isolate other input-blocking resources on staging. Restart cleans up called entities; H/J calls them again.

## Stop leading stuck

This beta reconciles the actual native led-horse handle and cancels stale permission responses. If the label remains, report exact steps and whether another script replaced the player's task or mounted them.

## Menu loading forever

Check model names, game build and memory pressure. Reduce vendor catalogues, tune EntryTimeoutMs/Preload or disable AllModels. Escape must cancel. If all models fail, the menu returns to gameplay with an error.

## Storage cannot open / sale refused

Check inventory name, start order and exact API version. Full native Inventory V2 compatibility is not certified. Non-empty/unverifiable bags block permanent removal. Check items **and weapons**, follow migration instructions and do not bypass the safeguard.

## Ride disappeared

Resource restart/stop, character switch, explicit flee/store or ownership/active changes can remove called entities without deleting DB ownership. Re-open My Stable and call again. If none applies, report reproduction steps and relevant scripts/logs.

## Camera, terrain or draft team

Check locations.lua against your map/IPLs, especially long-wagon clearance. Native draft teams depend on vehicle model; not every wagon has two horses. Boats/non-draft models do not gain a horse team.

## Money / gold

VORP Core wallet is authoritative. Cash/Gold chooses a method, not a second item currency. Check conversion/overrides. Server pricing ignores client-supplied values. Preserve private economy logs for crash reconciliation.

## Report a bug

Use GitHub Issues → Bug report. Include release, RedM/Core/inventory versions, steps and redacted errors. Never post passwords, keys, tokens, full server.cfg or private identifiers.
