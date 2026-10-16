# Testing and compatibility

## Beta evidence

- Lua fixtures cover authoritative pricing, ownership, cash/gold, capacities, equipment, consent transfers, refunds, stale sessions and concurrent mutation guards.
- 25 leading scenarios cover native state loss, cancellation, identity changes, interruption and bounded network-control acquisition.
- Client integration checks visible enabled prompt controls, late-response cancellation, model-load cancellation, cleanup, storage bindings and spawn reuse.
- Disposable MariaDB tests execute shipped Lua/SQL with Core/native fixtures. They are not two real RedM clients.
- Browser tests cover NUI, selectors, dialogs, cash/gold, keyboard Escape, loading and layout at 720p/1080p/1440p.
- The owner confirmed riding-horse Lead works and wagon Dismiss is visible. A native harnessed-draft test failed, so draft leading defaults off.

Fixtures cannot certify every native animation, game build, map or third-party resource.

## Staging checklist

1. Join/select a character; no startup/F8 errors.
2. G → loading → menu. Escape during load/menu restores movement/camera and removes the reading book.
3. Buy/name/select a horse; H calls it from clear distant ground. Calling again must reuse it.
4. Lead, stop, look away and target again several times. Cancel while approaching. The label must return to Lead.
5. Buy tack, remove/re-equip it free. Equipped must match the saved horse after reconnect.
6. Buy with gold and cash. Check Core balance and exact server prices.
7. J calls a wagon. Dismiss via wagon/draft horse, call again. Occupied/moving wagons must not be silently removed.
8. Sell an empty wagon; verify payout/currency. Repeated requests must not pay twice.
9. Put items/weapons in a bag, reopen/reconnect. Same-model rides must have separate bags. Non-empty/unverifiable storage must block permanent removal.
10. With another player, send an offer and accept/decline it. Test distance/full stable/disconnect and foreign ownership attempts.

Repeat camera/spawn checks at each enabled location. Test your actual inventory version before production.

## Portable developer tests

```sh
python -m pip install -r tests/requirements.txt
python tests/run.py
npm ci
npx playwright install chromium
npm run test:ui
```

These are development dependencies only; running the resource needs no Python/npm. Portable tests use fixtures and a headless browser, never your live server/database.
