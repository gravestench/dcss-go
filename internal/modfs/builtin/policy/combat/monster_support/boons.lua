local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local enchantments = require("constants.monster_enchantment")

local boons = {}

-- Example: boons.haste(ctx, monster, 100) makes its next actions faster.
-- Keep common enchantments on the actor, independent of the spell or brand
-- that granted them. Reapplying an effect extends but never shortens it.
local function grant(ctx, monster, field, duration)
    if duration <= 0 then
        error("monster boon duration must be positive")
    end

    local value = ctx:get(monster, component.MONSTER_BOONS) or {
        haste_aut = 0,
        might_aut = 0,
        swift_aut = 0,
    }

    value[field] = math.max(value[field], duration)

    if ctx:has(monster, component.MONSTER_BOONS) then
        ctx:set(monster, component.MONSTER_BOONS, value)
    else
        ctx:add(monster, component.MONSTER_BOONS, value)
    end
end

-- A haste beam and a Chaos brand both grant this single action-speed timer.
function boons.haste(ctx, monster, duration)
    grant(ctx, monster, "haste_aut", duration)
end

-- Might amplifies melee damage, with frenzy taking precedence on the source path.
function boons.might(ctx, monster, duration)
    grant(ctx, monster, "might_aut", duration)
end

-- Sprint changes movement energy rather than every monster action.
function boons.swift(ctx, monster, duration)
    grant(ctx, monster, "swift_aut", duration)
end

-- The presence of a record alone does not imply an active Haste effect.
function boons.hasted(ctx, monster)
    local value = ctx:get(monster, component.MONSTER_BOONS)

    return value ~= nil and value.haste_aut > 0
end

-- The presence of a record alone does not imply an active Might effect.
function boons.mighty(ctx, monster)
    local value = ctx:get(monster, component.MONSTER_BOONS)

    return value ~= nil and value.might_aut > 0
end

-- Sprint can end while a different boon on the same actor remains active.
function boons.swift_active(ctx, monster)
    local value = ctx:get(monster, component.MONSTER_BOONS)

    return value ~= nil and value.swift_aut > 0
end

-- Source monster Haste multiplies speed by three halves before energy is granted.
function boons.speed(ctx, monster, speed)
    if boons.hasted(ctx, monster) then
        return math.floor(speed * 3 / 2)
    end

    return speed
end

-- Source Might and frenzy do not multiply the same melee strike twice.
function boons.damage(ctx, monster, amount)
    if boons.mighty(ctx, monster) and
        not allegiance.frenzied(ctx, monster) then
        return math.floor(amount * 3 / 2)
    end

    return amount
end

-- Clear one complete enchant record after its independent timers expire.
function boons.tick(ctx, monster, elapsed_aut)
    local value = ctx:get(monster, component.MONSTER_BOONS)

    if not value then
        return
    end

    if value.haste_aut < enchantments.INFINITE_DURATION_AUT then
        value.haste_aut = math.max(0,
            value.haste_aut - elapsed_aut)
    end
    value.might_aut = math.max(0, value.might_aut - elapsed_aut)
    value.swift_aut = math.max(0, value.swift_aut - elapsed_aut)

    if value.haste_aut == 0 and value.might_aut == 0 and
        value.swift_aut == 0 then
        ctx:remove(monster, component.MONSTER_BOONS)
    else
        ctx:set(monster, component.MONSTER_BOONS, value)
    end
end

-- Unravelling strips beneficial magic but does not erase unrelated conditions.
function boons.dispel(ctx, monster)
    if not ctx:has(monster, component.MONSTER_BOONS) then
        return false
    end

    ctx:remove(monster, component.MONSTER_BOONS)

    return true
end

return boons
