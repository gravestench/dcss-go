local component = require("constants.component")
local chaos_effects = require("constants.chaos_effects")
local boons = require("policy.combat.monster_support.boons")

local status = {}

local fields = {
    [chaos_effects.AGILITY] = "agility_aut",
}

-- Chaos owns agility; generic boons have their own component because spells
-- grant them too. Shifter identity has its own owner for natural monsters.
local function current(ctx, monster)
    return ctx:get(monster, component.MONSTER_CHAOS)
end

-- Chaos agility affects combat only while its timer is positive.
local function active(ctx, monster, field)
    local value = current(ctx, monster)

    return value ~= nil and value[field] > 0
end

-- Delegate generic boons to their owner; keep Chaos-only agility local.
function status.apply(ctx, monster, name, duration)
    if name == chaos_effects.HASTE then
        boons.haste(ctx, monster, duration)

        return
    end

    if name == chaos_effects.MIGHT then
        boons.might(ctx, monster, duration)

        return
    end

    local field = fields[name]

    if not field then
        error("unknown chaos monster status " .. tostring(name))
    end

    local value = current(ctx, monster) or {
        agility_aut = 0,
    }

    value[field] = math.max(value[field], duration)

    if current(ctx, monster) then
        ctx:set(monster, component.MONSTER_CHAOS, value)
    else
        ctx:add(monster, component.MONSTER_CHAOS, value)
    end
end

-- Agility adds the source fixed evasion bonus only while active.
function status.evasion(ctx, monster, amount)
    -- Source: monster.cc and defines.h:AGILITY_BONUS.
    if active(ctx, monster, "agility_aut") then
        return amount + 5
    end

    return amount
end

-- Remove Chaos-only state after its final agility turn expires.
function status.tick(ctx, monster, aut)
    local value = current(ctx, monster)

    if not value then
        return
    end

    for _, field in pairs(fields) do
        value[field] = math.max(0, value[field] - aut)
    end

    if value.agility_aut == 0 then
        ctx:remove(monster, component.MONSTER_CHAOS)
    else
        ctx:set(monster, component.MONSTER_CHAOS, value)
    end
end

return status
