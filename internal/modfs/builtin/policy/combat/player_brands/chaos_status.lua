local component = require("constants.component")
local chaos_effects = require("constants.chaos_effects")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local monster_stats = require("policy.combat.monster_stats")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local roll = require("policy.combat.roll")

local status = {}

local fields = {
    [chaos_effects.HASTE] = "haste_aut",
    [chaos_effects.MIGHT] = "might_aut",
    [chaos_effects.AGILITY] = "agility_aut",
}

local function current(ctx, monster)
    return ctx:get(monster, component.MONSTER_CHAOS)
end

local function active(ctx, monster, field)
    local value = current(ctx, monster)

    return value ~= nil and value[field] > 0
end

function status.apply(ctx, monster, name, duration)
    local field = fields[name]

    if not field then
        error("unknown chaos monster status " .. tostring(name))
    end

    local value = current(ctx, monster) or {
        haste_aut = 0,
        might_aut = 0,
        agility_aut = 0,
        shifter = false,
    }

    value[field] = math.max(value[field], duration)

    if current(ctx, monster) then
        ctx:set(monster, component.MONSTER_CHAOS, value)
    else
        ctx:add(monster, component.MONSTER_CHAOS, value)
    end
end

function status.make_shifter(ctx, monster)
    local value = current(ctx, monster) or {
        haste_aut = 0,
        might_aut = 0,
        agility_aut = 0,
        shifter = false,
    }

    value.shifter = true

    if current(ctx, monster) then
        ctx:set(monster, component.MONSTER_CHAOS, value)
    else
        ctx:add(monster, component.MONSTER_CHAOS, value)
    end
end

function status.shifter_active(ctx, monster)
    local value = current(ctx, monster)

    return value ~= nil and value.shifter
end

function status.shift(ctx, monster)
    if not status.shifter_active(ctx, monster) or
        ctx:has(monster, component.PARALYSIS) then
        return false
    end

    local stasis = ctx:get(monster, component.MONSTER_STASIS)

    if stasis and (stasis.hibernating or stasis.petrifying_aut > 0 or
        stasis.petrified_aut > 0) then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.hit_dice(ctx, monster, definition)

    -- Source: mon-ench.cc:1686-1694. Ordinary shifters change on roughly
    -- one in three times their hit dice monster actions.
    if roll.melee(ctx, 3 * hd) ~= 0 then
        return false
    end

    return polymorph.shapeshift(ctx, monster, definition)
end

function status.speed(ctx, monster, speed)
    if active(ctx, monster, "haste_aut") then
        return math.floor(speed * 3 / 2)
    end

    return speed
end

function status.damage(ctx, monster, amount)
    -- Source: melee-attack.cc:3559-3560.
    if active(ctx, monster, "might_aut") and
        not allegiance.frenzied(ctx, monster) then
        return math.floor(amount * 3 / 2)
    end

    return amount
end

function status.evasion(ctx, monster, amount)
    -- Source: monster.cc:3301-3302 and defines.h:AGILITY_BONUS.
    if active(ctx, monster, "agility_aut") then
        return amount + 5
    end

    return amount
end

function status.tick(ctx, monster, aut)
    local value = current(ctx, monster)

    if not value then
        return
    end

    for _, field in pairs(fields) do
        value[field] = math.max(0, value[field] - aut)
    end

    if value.haste_aut == 0 and value.might_aut == 0 and
        value.agility_aut == 0 and not value.shifter then
        ctx:remove(monster, component.MONSTER_CHAOS)
    else
        ctx:set(monster, component.MONSTER_CHAOS, value)
    end
end

return status
