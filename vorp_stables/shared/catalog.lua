StableCatalog = {}
local C = StableCatalog

function C.integer(value)
    return type(value) == 'number' and value == value and value % 1 == 0 and value > 0 and value < 2147483647
end

function C.amount(value)
    return type(value) == 'number'
        and value == value
        and value >= 0
        and value <= 1000000
        and math.abs(value * 100 - math.floor(value * 100 + 0.5)) < 0.000001
end

function C.name(value)
    if type(value) ~= 'string' then
        return
    end
    value = value:match('^%s*(.-)%s*$')
    local ok, length = pcall(utf8.len, value)
    if not ok or not length or length < 3 or length > 30 or value:find('[%c<>]') then
        return
    end
    return value
end

function C.pretty(value)
    return (tostring(value):gsub('_PC$', ''):gsub('_', ' '):gsub('(%l)(%u)', '%1 %2'))
end

function C.details(model, kind)
    if kind == 'cart' then
        return C.pretty(model), 'Wagon'
    end
    local breed, coat = model:match('^[Aa]_[Cc]_[Hh]orse_(.-)_(.+)$')
    return C.pretty(breed or model:gsub('^[Aa]_[Cc]_', '')), C.pretty(coat or 'Standard')
end

function C.price(stableIndex, kind, model)
    if kind ~= 'horse' and kind ~= 'cart' then
        return
    end
    local stable = Config.Stables[stableIndex]
    local all = kind == 'horse' and Data.Horses or Data.Carts
    if not stable or not all[model] then
        return
    end
    local available = kind == 'horse' and stable.horses or stable.carts
    if not available or not next(available) then
        return all[model]
    end
    if available[model] ~= nil then
        return tonumber(available[model])
    end
    for _, entry in ipairs(available) do
        if entry == model then
            return all[model]
        end
    end
end

function C.goldPrice(cash, key)
    local settings = Config.Payments or {}
    if settings.GoldEnabled ~= true then
        return nil
    end
    local overrides = settings.GoldPrices or {}
    local price = overrides[tostring(key)]
    if price == nil then
        local rate = tonumber(settings.CashPerGold)
        if not rate or rate <= 0 or rate ~= rate then
            return nil
        end
        price = math.ceil(cash / rate * 100) / 100
    end
    if C.amount(price) then
        return price
    end
end

function C.payment(currency, cash, key)
    if currency == nil or currency == 'cash' then
        return cash, 'cash'
    end
    if currency == 'gold' then
        return C.goldPrice(cash, key), 'gold'
    end
end

function C.receipt(status)
    if type(status) == 'table' and C.amount(status.purchasePrice) then
        return {
            purchasePrice = status.purchasePrice,
            purchaseCurrency = status.purchaseCurrency == 'gold' and 'gold' or 'cash',
        }
    end
    return false
end

function C.rides(stableIndex, kind)
    local groups, byName = {}, {}
    for model in pairs(kind == 'horse' and Data.Horses or Data.Carts) do
        local price = C.price(stableIndex, kind, model)
        if price then
            local breed, coat = C.details(model, kind)
            local key = kind == 'horse' and breed or model
            local group = byName[key]
            if not group then
                group = { name = breed, kind = kind, coats = {} }
                byName[key] = group
                groups[#groups + 1] = group
            end
            group.coats[#group.coats + 1] = {
                name = coat,
                model = model,
                price = price,
                goldPrice = C.goldPrice(price, model),
                thumbnail = (Config.Thumbnails or {})[model],
            }
        end
    end
    table.sort(groups, function(a, b)
        return a.name < b.name
    end)
    for _, group in ipairs(groups) do
        table.sort(group.coats, function(a, b)
            return a.name < b.name
        end)
    end
    return groups
end

function C.equipment(family, hash)
    hash = tonumber(hash)
    local models = Data.Complements[family]
    if not models then
        return
    end
    for name, variants in pairs(models) do
        for i = 1, #variants - 1 do
            if tonumber(variants[i]) == hash then
                return {
                    family = family,
                    hash = hash,
                    name = name,
                    price = math.floor(
                        variants[#variants] * (Config.EquipmentPriceMultiplier or 10) * 100 + 0.5
                    ) / 100,
                }
            end
        end
    end
end

function C.equipmentGroups()
    local groups = {}
    for family, models in pairs(Data.Complements) do
        local items = {}
        for name, variants in pairs(models) do
            local coats = {}
            for i = 1, #variants - 1 do
                local item = C.equipment(family, variants[i])
                coats[#coats + 1] = {
                    name = 'Variant ' .. i,
                    hash = item.hash,
                    price = item.price,
                    goldPrice = C.goldPrice(item.price, item.hash),
                    thumbnail = (Config.Thumbnails or {})[tostring(item.hash)],
                }
            end
            items[#items + 1] = { name = name, family = family, kind = 'equipment', coats = coats }
        end
        table.sort(items, function(a, b)
            return a.name < b.name
        end)
        groups[#groups + 1] = { name = family, items = items }
    end
    table.sort(groups, function(a, b)
        if a.name == 'Saddles' then
            return b.name ~= 'Saddles'
        elseif b.name == 'Saddles' then
            return false
        end
        return a.name < b.name
    end)
    return groups
end

-- New purchases retain their paid price; legacy records fall back to the base catalogue.
function StableCatalog.wagonSalePrice(model, paid)
    local price = tonumber(paid)
    if not StableCatalog.amount(price) then
        price = Data.Carts[model]
    end
    if not price then
        return nil
    end
    local percent = math.max(0, math.min(100, tonumber(Config.WagonSellPercent) or 60))
    return math.floor(price * percent) / 100
end
