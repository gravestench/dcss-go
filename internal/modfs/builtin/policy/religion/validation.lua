-- A saved worship record must be a possible live state before any god rule
-- reads it. This owner checks IDs and arithmetic bounds in one place.
local component = require("constants.component")
local gods = require("constants.gods")
local limits = require("constants.piety")
local categories = require("constants.catalog")

local validation = {}
-- Resolve current IDs at the boundary so a mod's added god is valid in a
-- restored run, while the temporary ecumenical altar can never be worshipped.
local function known_gods()
    local known = {
        [gods.NO_GOD] = true,
    }

    for _, id in ipairs(register.ids(categories.GODS)) do
        known[id] = true
    end

    return known
end

-- Check a per-god counter map without assuming every god has an entry.
local function history(name, values, maximum, known)
    for id, value in pairs(values) do
        if not known[id] or value < 0 or
            (maximum and value > maximum) then
            error("invalid worship " .. name .. " for " .. tostring(id))
        end
    end
end

-- Enforce the source piety range and reject forged god IDs after a save is
-- restored. God-specific effects will use this same checked record.
function validation.check(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local known = known_gods()

    if not state then
        error("player lacks religion worship")
    end

    if not known[state.god_id] then
        error("unknown worship god " .. tostring(state.god_id))
    end

    if not known[state.previous_good_god] then
        error("unknown previous good god " ..
            tostring(state.previous_good_god))
    end

    if state.piety < 0 or state.piety > limits.MAX or
        state.piety_hysteresis < 0 or
        state.piety_hysteresis > limits.HYSTERESIS_LIMIT or
        state.gift_timeout < 0 or
        state.saved_good_piety < 0 or
        state.saved_good_piety > limits.MAX or
        state.min_ignis_piety < 0 or
        state.min_ignis_piety > limits.MAX then
        error("invalid worship piety state")
    end

    if state.god_id == gods.NO_GOD and state.piety ~= 0 then
        error("godless player has piety")
    end

    history("penance", state.penance, nil, known)
    history("worshipped", state.worshipped, 100, known)
    history("piety maximum", state.piety_max, limits.MAX, known)

    return state
end

return validation
