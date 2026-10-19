local brands = require("policy.combat.brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_health = require("policy.combat.monster_health")
local monster_poison = require("policy.combat.monster_poison")
local monster_slow = require("policy.combat.monster_slow")
local player_health = require("policy.combat.player_health")
local player_resistance = require("policy.combat.player_resistance")
local player_slow = require("policy.character.slow")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")

local curare = {}

local function dice(ctx, count, sides, stream)
    local total = 0

    for _ = 1, count do
        total = total + 1 + ctx:random(stream, sides)
    end

    return total
end

-- beam.cc:curare_actor applies poison, 2d6 breath damage, then slow.
-- Fully poison-resistant monsters ignore all three effects.
function curare.apply(ctx, source, target, stream)
    stream = stream or streams.MONSTER_SPELL

    if ctx:has(target, component.PLAYER) then
        local resistance = player_resistance.poison(ctx, target)

        if resistance >= 3 or resistance > 0 and
            ctx:random(stream, 3) ~= 0 then
            return false
        end

        local actor = ctx:get(source, component.ACTOR)

        brands.poison(ctx, dice(ctx, 2, 12, stream) + 1,
            actor.kind_id)
        ctx:emit("combat", "You have difficulty breathing.")
        player_health.damage(ctx, target, dice(ctx, 2, 6, stream),
            false, source)
        player_slow.apply(ctx, target,
            10 + ctx:random(stream, 2 + ctx:random(stream, 6)))

        return true
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if ctx:get(target, component.HEALTH).current <= 0 or
        monster_poison.effective_resistance(ctx, target, definition) > 0 then
        return false
    end

    monster_poison.apply(ctx, target, definition, 2, source)
    local damage = dice(ctx, 2, 6, stream)

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("combat", "The " .. definition.name .. " convulses.")
    end
    local health = monster_health.damage(ctx, target, damage, source)

    if health.current > 0 then
        monster_slow.apply(ctx, target, definition)
    end

    return true
end

return curare
