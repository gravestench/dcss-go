-- A saved worship record must be a possible live state before any god rule
-- reads it. This owner checks IDs and arithmetic bounds in one place.
local component = require("constants.component")
local catalog = require("policy.catalog")
local gods = require("constants.gods")
local limits = require("constants.piety")
local tithe_rules = require("constants.zin_tithe_rules")
local wallet_limits = require("constants.wallet_limits")
local categories = require("constants.catalog")
local ru_pools = require("data.ru_variant_mutations")

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
        ru.sacrifice_penalty < 0 or ru.sacrifice_mutations < 0) then
        error("invalid Ru sacrifice progress")
    end

    if ru then
        local offered = {}
        local active_pools = {}

        -- An offer stores IDs and prices, never copied definitions. On
        -- restore every ID must still resolve in the effective mod catalog.
        for _, id in ipairs(ru.available) do
            if offered[id] then
                error("duplicate saved Ru sacrifice " .. id)
            end

            local definition = catalog.get(
                categories.RU_SACRIFICES, id)

            offered[id] = true

            if definition.variant_pool then
                active_pools[definition.variant_pool] = true
            end

            if not ru.quoted_piety[id] or
                ru.quoted_piety[id] <= 0 then
                error("saved Ru sacrifice lacks a price")
            end
        end

        for id in pairs(ru.quoted_piety) do
            if not offered[id] then
                error("saved Ru price has no offer " .. id)
            end
        end

        for _, field in ipairs({
            "health", "essence", "purity", "arcana",
        }) do
            local selected = ru[field]
            local expected = field == "arcana" and 3 or 1

            if #selected ~= (active_pools[field] and expected or 0) then
                error("saved Ru variant set is incomplete")
            end

            for index, id in ipairs(selected) do
                catalog.get(categories.MUTATIONS, id)

                local pool = ru_pools[field]
                local choices = field == "arcana" and
                    pool[index] or pool
                local member = false

                for _, candidate in ipairs(choices) do
                    member = member or candidate == id
                end

                if not member then
                    error("saved Ru variant is outside its pool")
                end
            end
        end
    end

    local xom_trail = ctx:get(player, component.XOM_CLOUD_TRAIL)

    if xom_trail then
        if xom_trail.remaining_aut <= 0 or
            xom_trail.remaining_aut > 1200 then
            error("invalid Xom cloud trail duration")
        end

        -- A modded trail can choose a new registered kind, but an unknown
        -- saved ID cannot silently become a different cloud on movement.
        catalog.get(categories.CLOUDS, xom_trail.cloud_kind)
    end

    local xom_stairs = ctx:get(player, component.XOM_STAIR_REPEL)

    if xom_stairs and
        (xom_stairs.move_aut < 0 or xom_stairs.move_aut > 1000 or
            xom_stairs.climb_aut < 0 or xom_stairs.climb_aut > 500 or
            (xom_stairs.move_aut == 0 and
                xom_stairs.climb_aut == 0)) then
        error("invalid Xom stair repulsion duration")
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
