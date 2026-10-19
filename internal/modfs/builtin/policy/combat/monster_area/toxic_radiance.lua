-- Monster Toxic Radiance is a moving LOS_NO_TRANS aura. Unlike the player
-- version, source monsters omit aligned actors from every pulse. The spell
-- file starts the timer; this policy owns target eligibility and poison.
-- Source: spl-damage.cc:toxic_radiance_effect and _toxic_can_affect.
local actors = require("policy.combat.monster_area.actors")
local brands = require("policy.combat.brands")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local poison = require("policy.combat.monster_poison")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local player_resistance = require("policy.combat.player_resistance")

local radiance = {}
local SIGHT_RADIUS = 7
local POISON_DIE_SIDES = 3

-- Source resist_adjust_damage gives poison a boolean-resistance bonus.
-- The generic elemental helper excludes player poison by design, so this
-- small calculation uses the player's actual rPois before HP ownership.
local function player_poison_damage(ctx, target, raw)
    local resistance = player_resistance.poison(ctx, target)

    if resistance >= 3 then
        return 0
    end

    if resistance > 0 then
        local divisor = math.floor((3 * resistance + 1) / 2) + 1

        return math.floor(raw / divisor)
    end

    if resistance < 0 then
        return math.floor(raw * 3 / 2)
    end

    return raw
end

-- Virulence changes a live monster's effective rPois without changing its
-- catalog definition. Eligibility and damage must read the same level.
local function monster_poison_damage(ctx, target, raw)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local resistance = poison.effective_resistance(ctx,
        target, definition)

    if resistance < 0 then
        return math.floor(raw * 3 / 2)
    end

    return raw
end

-- The source skips actors whose poison resistance makes this aura
-- ineffective. Keep the same answer in AI and resolution. Submergence has
-- no live ECS state yet, so that source filter belongs to its later port.
function radiance.susceptible(ctx, target)
    if ctx:has(target, component.PLAYER) then
        return player_resistance.poison(ctx, target) < 3
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return poison.effective_resistance(ctx, target, definition) < 1
end

-- A monster can avoid wasting a cast when its only visible bodies are
-- allies, immune enemies, or itself. The pulse repeats this live query.
function radiance.victims(ctx, caster)
    local found = {}

    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if not targets.aligned(ctx, caster, target) and
            radiance.susceptible(ctx, target) then
            found[#found + 1] = target
        end
    end

    return found
end

-- The source rolls one damage die per pulse, then a separate poison dose.
-- A surviving monster always gets at least one first poison level.
local function poison_monster(ctx, caster, target)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local levels = ctx:random(streams.MONSTER_SPELL, 2)

    if not ctx:has(target, component.PROJECTILE_POISON) then
        levels = math.max(1, levels)
    end

    poison.apply(ctx, target, definition, levels, caster, false)
end

-- Player poison is a separate condition from the immediate poison-flavoured
-- HP hit. Source rolls two three-sided dice even if resistance reduced HP.
local function poison_player(ctx, caster)
    local amount = 2 +
        ctx:random(streams.MONSTER_SPELL, POISON_DIE_SIDES) +
        ctx:random(streams.MONSTER_SPELL, POISON_DIE_SIDES)

    local actor = ctx:get(caster, component.ACTOR)

    brands.poison(ctx, amount, actor.kind_id)
end

-- Use current positions on every pulse; the aura follows a moving caster
-- and can reach enemies that entered LOS after the original cast.
function radiance.pulse(ctx, caster, power)
    for _, target in ipairs(radiance.victims(ctx, caster)) do
        local raw = 1 + ctx:random(streams.MONSTER_SPELL,
            1 + math.floor(power / 20))
        local amount

        if ctx:has(target, component.PLAYER) then
            amount = player_poison_damage(ctx, target, raw)
        else
            amount = monster_poison_damage(ctx, target, raw)
        end

        direct.damage(ctx, caster, target, amount)

        local health = ctx:get(target, component.HEALTH)

        if health and health.current > 0 then
            if ctx:has(target, component.PLAYER) then
                poison_player(ctx, caster)
            else
                poison_monster(ctx, caster, target)
            end
        end
    end
end

return radiance
