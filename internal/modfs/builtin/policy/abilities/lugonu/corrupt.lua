-- Theory of operation: the fourth-star invocation pays its divine costs
-- after the world owner permanently corrupts the current level. That
-- owner stores one or more nexus entities, changes eligible grid cells,
-- and runs the immediate servant burst. Expired nexuses still bar reuse.
local abilities = require("ids.abilities")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local registry = require("policy.abilities.registry")
local skills = require("ids.skills")
local world = require("policy.world.lugonu_corruption")

local corrupt = {}

-- Source permits one corruption of each non-Abyss floor. The saved
-- nexus marker, even with an expired clock, owns that restriction.
function corrupt.available(ctx, player)
    local position = ctx:get(player, component.POSITION)

    return costs.available(ctx, player, gods.LUGONU, 4) and
        position ~= nil and not world.corrupted(ctx, position.level_id)
end

-- Insufficient MP or the fixed five HP cost rejects before time passes.
function corrupt.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 7) then
        return "You do not have enough magic."
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.current <= 5 then
        return "You do not have enough health."
    end

    return nil
end

-- A failed invocation consumes only time. Its power depends on live
-- Invocations; terrain and servant effects are owned by the world policy.
function corrupt.resolve(ctx, player)
    if costs.failed(ctx, player, 70, 4, 25) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    local power = 300 + magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 15)

    world.apply(ctx, player, power)
    costs.spend(ctx, player, 7, costs.piety_cost(ctx, 10))

    local health = ctx:get(player, component.HEALTH)

    health.current = health.current - 5
    ctx:set(player, component.HEALTH, health)
end

registry.add(abilities.LUGONU_CORRUPT, {
    name = "Corrupt",
    available = corrupt.available,
    prepare = corrupt.prepare,
    resolve = corrupt.resolve,
})

return corrupt
