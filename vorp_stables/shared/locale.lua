StableLocale = {}
local S = StableLocale

local function load(code)
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. code .. '.json')
    if not raw then
        return nil
    end
    local ok, messages = pcall(json.decode, raw)
    if ok and type(messages) == 'table' then
        return messages
    end
end

S.messages = load('en') or {}
local code = type(Config.Locale) == 'string' and Config.Locale:match('^[a-z][a-z]$') and Config.Locale or 'en'
local translated = code ~= 'en' and load(code) or nil
S.code = translated and code or 'en'
for key, value in pairs(translated or {}) do
    if type(value) == 'string' then
        S.messages[key] = value
    end
end

function S.text(key, values)
    if type(key) ~= 'string' then
        return key
    end
    return (
        (S.messages[key] or key):gsub('{([%w_]+)}', function(name)
            return values and values[name] ~= nil and tostring(values[name]) or '{' .. name .. '}'
        end)
    )
end

function S.stableName(name)
    local location = type(name) == 'string' and name:match('^(.*) Stable$')
    return location and S.text('{location} Stable', { location = location }) or name
end
