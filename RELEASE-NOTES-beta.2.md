# 330 Stables for VORP — beta.2

Fix native VORP's empty/unregistered bag verification, discovered in an isolated real migration test from VORP Stables 1.3. Loaded or unverified storage still blocks permanent removal.

Original 1.3 registered legacy bags using the real native inventory API; six ownership/gear records survived replacement unchanged. Explicitly mapped fixture bag items/weapons persisted without duplication. Twenty native migration/storage checks passed after an inventory/stable restart. See docs/NATIVE-INVENTORY-VALIDATION.md.

This remains a beta. Player acceptance of native inventory UI, transfers and reconnect is separate. Old shared-model bags are not blindly auto-imported; follow docs/MIGRATION.md. UI remains compiled-only, without source maps.
