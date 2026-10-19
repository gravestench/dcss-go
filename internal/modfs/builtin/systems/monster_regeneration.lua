-- Theory of operation: Living monsters heal on their active turn before poison and decision systems.
-- Natural monster regeneration from mon-act.cc,1724 and
-- monster.cc. The active floor scheduler supplies action order.

local catalog = require("policy.catalog")
local habitat = require("policy.combat.monster_habitat")
local hand = require("policy.combat.monster_support.trogs_hand")

-- Keep fractional healing deterministic through the named RNG stream instead of truncating every turn.
local function random_divide(ctx, numerator, denominator)
    if numerator <= 0 then
        return 0
    end

    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("monster_regen", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Test catalog flag membership before applying regeneration exceptions.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local system = {}

-- Monster healing is calculated before AI evaluates current HP and position.
function system.update(ctx, entity)
    if not ctx:has(entity, "core.ai") then
        return
    end

    local actor = ctx:get(entity, "core.actor")
    local health = ctx:get(entity, "core.health")

    if not actor then
        error("regenerating monster has no actor")
    end

    if not health or health.current < 0 or health.max <= 0 or
        health.current > health.max then
        error("regenerating monster has invalid health")
    end

    if health.current == 0 or health.current == health.max then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if has_flag(definition.flags, "M_NO_REGEN") and
        not hand.active(ctx, entity) then
        return
    end

    local position = ctx:get(entity, "core.position")

    if position and not habitat.at(ctx, entity, position.level_id,
        position.x, position.y) then
        return
    end

    if actor.kind_id == "MONS_PARGHIT" then
        health.current = math.min(health.max, health.current + 27)
    elseif has_flag(definition.flags, "M_FAST_REGEN") or
        hand.active(ctx, entity) then
        health.current = health.current + 1
    elseif definition.hd >= 1 and definition.hd <= 2 then
        if ctx:random("monster_regen", 25) == 0 then
            health.current = health.current + 1
        end
    else
        local divider = math.max(1,
            random_divide(ctx, 15 - definition.hd, 4))
        local rate = math.max(1,
            random_divide(ctx, definition.hd, divider))

        if ctx:random("monster_regen", 25) < rate then
            health.current = health.current + 1
        end
    end

    ctx:set(entity, "core.health", health)
end

register.system({
    id = "monster.regeneration",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
