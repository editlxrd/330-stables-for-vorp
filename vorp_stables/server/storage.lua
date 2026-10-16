StableStorage = {}

function StableStorage.empty(row)
    local ok, empty = pcall(function()
        if GetResourceState('lab_inventory') == 'started' then
            local kind = row.type == 'horse' and 'horse' or 'wagon'
            local data = exports.lab_inventory:ReadContainer(kind .. ':vorp_stables:' .. row.id)
            return data == nil or (type(data.slots) == 'table' and next(data.slots) == nil)
        end
        if GetResourceState('vorp_inventory') ~= 'started' then
            return false
        end
        -- Check both the per-ride ID and the legacy model/character bag.
        for _, id in ipairs({ 'stable_' .. row.id, row.modelname .. '_' .. row.charidentifier }) do
            -- Native VORP returns false for unregistered bags, even when their DB contents are empty.
            -- Registration creates runtime metadata only; it does not copy or clear stored contents.
            if not exports.vorp_inventory:isCustomInventoryRegistered(id) then
                exports.vorp_inventory:registerInventory({
                    id = id,
                    name = row.name or 'Stable storage',
                    limit = Config.CustomMaxWeight[row.modelname] or Config.DefaultMaxWeight,
                    acceptWeapons = true,
                    shared = false,
                    ignoreItemStackLimit = Config.StackInvIgnore[row.type],
                })
                if not exports.vorp_inventory:isCustomInventoryRegistered(id) then
                    return false
                end
            end
            local items = exports.vorp_inventory:getCustomInventoryItems(id)
            local weapons = exports.vorp_inventory:getCustomInventoryWeapons(id)
            if
                type(items) ~= 'table'
                or type(weapons) ~= 'table'
                or next(items) ~= nil
                or next(weapons) ~= nil
            then
                return false
            end
        end
        return true
    end)
    return ok and empty == true
end
