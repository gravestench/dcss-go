-- A saved worship record must be a possible live state before any god rule
-- reads it. This owner checks IDs and arithmetic bounds in one place.
local component = require("constants.component")
local gods = require("constants.gods")
local limits = require("constants.piety")
local tithe_rules = require("constants.zin_tithe_rules")
local wallet_limits = require("constants.wallet_limits")
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
        state.next_god_time_aut < 0 or
        (state.next_god_time_aut > 0 and
            (state.next_god_time_aut <= ctx:aut() or
                state.next_god_time_aut > ctx:aut() + 300)) or
        state.saved_good_piety < 0 or
        state.saved_good_piety > limits.MAX or
        state.min_ignis_piety < 0 or
        state.min_ignis_piety > limits.MAX then
        error("invalid worship piety state")
    end

    if state.god_id == gods.NO_GOD and state.piety ~= 0 then
        error("godless player has piety")
    end

    local wallet = ctx:get(player, component.WALLET)

    if wallet and (wallet.gold < 0 or
        wallet.gold > wallet_limits.MAX_EXACT or
        wallet.generated_gold < 0 or
        wallet.generated_gold > wallet_limits.MAX_EXACT or
        wallet.gozag_gold_used < 0 or
        wallet.gozag_gold_used > wallet_limits.MAX_EXACT or
        wallet.donations < 0 or
        wallet.donations > wallet_limits.MAX_EXACT or
        wallet.tithe_base < 0 or
        wallet.tithe_base >= tithe_rules.DIVISOR) then
        error("invalid worship wallet counters")
    end

    local ash = ctx:get(player, component.RELIGION_ASHENZARI)

    if ash and (ash.curse_progress < 0 or ash.curse_delay < 0) then
        error("invalid Ashenzari curse progress")
    end

    local ru = ctx:get(player, component.RELIGION_RU)

    if ru and (ru.sacrifice_progress < 0 or ru.sacrifice_delay < 0 or
        ru.sacrifice_penalty < 0) then
        error("invalid Ru sacrifice progress")
    end

    local xom = ctx:get(player, component.RELIGION_XOM)

    if xom and xom.pending_stimulation < 0 then
        error("invalid Xom stimulation")
    end

    local yred = ctx:get(player, component.RELIGION_YREDELEMNUL)

    if yred and yred.pending_bonus_stars < 0 then
        error("invalid Yredelemnul bonus")
    end

    history("penance", state.penance, nil, known)
    history("worshipped", state.worshipped, 100, known)
    history("piety maximum", state.piety_max, limits.MAX, known)
    history("current gifts", state.gift_current, nil, known)
    history("total gifts", state.gift_total, nil, known)

    for id, count in pairs(state.gift_current) do
        if count > (state.gift_total[id] or 0) then
            error("current gifts exceed lifetime gifts for " .. id)
        end
    end

    return state
end

return validation
