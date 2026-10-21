-- DES fog markers contain a flat constructor table. Read its values into
-- the port's own machine state without loading the legacy marker classes.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_names = require("constants.fog_clouds")

local fog = {}

local numeric = {
    walk_dist = true,
    pow_min = true,
    pow_max = true,
    pow_rolls = true,
    delay = true,
    delay_min = true,
    delay_max = true,
    size = true,
    size_min = true,
    size_max = true,
    size_buildup_amnt = true,
    size_buildup_time = true,
    spread_rate = true,
    spread_buildup_amnt = true,
    spread_buildup_time = true,
    start_clouds = true,
    excl_rad = true,
}

-- These two keys appear in one committed source vault, but its source
-- FogMachine:new ignores them. Retaining that behavior avoids inventing a
-- cloud buildup that DCSS never performs for that map.
local legacy_ignored = {
    buildup_amnt = true,
    buildup_time = true,
}

-- Name an authored failure with its map and source position when available.
local function invalid(site, reason)
    local name = site and (site.vault_id or site.source_id) or "fog marker"
    local path = site and (site.path or
        (site.arguments and site.arguments.path))
    local line = site and site.line

    if path and line then
        error(string.format("%s:%d: %s: %s",
            path, line, tostring(name), reason))
    end

    error(tostring(name) .. ": " .. reason)
end

-- A plain value reader permits quoted cloud names and integral source
-- parameters. It rejects code expressions instead of evaluating DES Lua.
local function fields(identity, site)
    local body = identity:match("^%s*lua:fog_machine%s*(%b{})%s*$")

    if not body then
        invalid(site, "invalid fog machine constructor")
    end

    body = body:sub(2, -2)
    local values = {}

    while true do
        body = body:gsub("^[%s,]+", "")

        if body == "" then
            break
        end

        local key, rest = body:match("^([%a_][%w_]*)%s*=%s*(.*)$")

        if not key or values[key] ~= nil then
            invalid(site, "malformed or duplicate fog parameter")
        end

        local quoted, tail = rest:match('^"([^"]*)"(.*)$')

        if not quoted then
            quoted, tail = rest:match("^'([^']*)'(.*)$")
        end
        local value

        if quoted then
            value = quoted
            body = tail
        else
            local number

            number, tail = rest:match("^(-?%d+)(.*)$")

            if not number then
                invalid(site, "fog parameter " .. key ..
                    " must be an integer or quoted name")
            end

            value = tonumber(number)
            body = tail
        end

        if not body:match("^%s*,") and not body:match("^%s*$") then
            invalid(site, "fog parameters need comma separators")
        end

        values[key] = value
    end

    return values
end

-- Check each normalized numeric range before it can become saved ECS state.
local function range(site, name, value, minimum, maximum)
    if type(value) ~= "number" or value % 1 ~= 0 or
        value < minimum or (maximum and value > maximum) then
        invalid(site, "invalid fog " .. name)
    end
end

-- Make one cloud ID and all source defaults explicit. Unknown names fail
-- before a level can be installed or its marker can be saved.
function fog.parse(identity, site)
    local source = fields(identity, site)

    for key, value in pairs(source) do
        if not numeric[key] and key ~= "cloud_type" and
            key ~= "kill_cat" and not legacy_ignored[key] then
            invalid(site, "unsupported fog parameter " .. key)
        end

        if numeric[key] and type(value) ~= "number" then
            invalid(site, "fog parameter " .. key .. " must be numeric")
        end
    end

    local name = source.cloud_type or "thin mist"
    local kind_id = cloud_names[name]

    if not kind_id or not catalog.get(categories.CLOUDS, kind_id) then
        invalid(site, "unknown fog cloud " .. tostring(name))
    end

    if source.kill_cat and source.kill_cat ~= "other" then
        invalid(site, "unsupported fog kill category")
    end

    local delay_min = source.delay_min or source.delay
    local delay_max = source.delay_max or source.delay
    local size_min = source.size_min or source.size
    local size_max = source.size_max or source.size
    local state = {
        kind_id = kind_id,
        walk_dist = source.walk_dist or 0,
        pow_min = source.pow_min or 1,
        pow_max = source.pow_max,
        pow_rolls = source.pow_rolls or 3,
        delay_min = delay_min,
        delay_max = delay_max,
        size_min = size_min,
        size_max = size_max,
        size_buildup_amnt = source.size_buildup_amnt or 0,
        size_buildup_time = source.size_buildup_time or 1,
        spread_rate = source.spread_rate or -1,
        spread_buildup_amnt = source.spread_buildup_amnt or 0,
        spread_buildup_time = source.spread_buildup_time or 1,
        start_clouds = source.start_clouds or 1,
        exclusion_radius = source.excl_rad or 1,
    }

    range(site, "power minimum", state.pow_min, 0)
    range(site, "power maximum", state.pow_max, 1)
    range(site, "power rolls", state.pow_rolls, 1)
    range(site, "delay minimum", state.delay_min, 1)
    range(site, "delay maximum", state.delay_max, state.delay_min)
    range(site, "size minimum", state.size_min, 1)
    range(site, "size maximum", state.size_max, state.size_min)
    range(site, "walk distance", state.walk_dist, 0)
    range(site, "start clouds", state.start_clouds, 0)
    range(site, "spread rate", state.spread_rate, -1, 100)
    range(site, "size buildup amount", state.size_buildup_amnt, 0)
    range(site, "size buildup time", state.size_buildup_time, 1)
    range(site, "spread buildup amount", state.spread_buildup_amnt, 0)
    range(site, "spread buildup time", state.spread_buildup_time, 1)
    range(site, "exclusion radius", state.exclusion_radius, -1)

    if state.pow_max < state.pow_min then
        invalid(site, "fog maximum power is below its minimum")
    end

    return state
end

-- Other marker families keep their own parser and lifecycle.
function fog.is_marker(identity)
    return type(identity) == "string" and
        identity:match("^%s*lua:fog_machine%s*%{") ~= nil
end

return fog
