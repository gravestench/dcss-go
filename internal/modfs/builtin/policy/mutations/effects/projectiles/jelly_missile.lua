local catalog = require("policy.catalog")
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local categories = require("constants.catalog")
local classes = require("constants.item_classes")
local channels = require("constants.message_channels")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")

local jelly = {}

function jelly.capability(level)
    return level > 0 and 1 or 0
end

-- Source: beam.cc eats an eligible missile after it hits the player,
-- then heals random2(final_dam / 2) on a coin flip.
function jelly.absorb(ctx, player, projectile_id, final_damage)
    if effects.sum(ctx, player, capabilities.PROJECTILE_ABSORPTION) == 0 then
        return false
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.current <= 0 or
        health.current >= health.max or
        statuses.death_door_active(ctx, player) then
        return false
    end

    local projectile = catalog.get(categories.ITEMS, projectile_id)

    if projectile.class ~= classes.MISSILES or not projectile.missile or
        ctx:random("mutation", 2) ~= 0 then
        return false
    end

    ctx:emit(channels.COMBAT, "Your attached jelly eats the " ..
        projectile.name .. "!")

    local maximum = math.floor(final_damage / 2)
    local recovered = maximum > 0 and
        ctx:random("mutation", maximum) or 0

    if recovered > 0 then
        health.current = math.min(health.max, health.current + recovered)
        ctx:set(player, component.HEALTH, health)
        ctx:emit(channels.DURATION, "You feel better.")
    end

    return true
end

effects.add(mutations.MUT_JELLY_MISSILE, {
    [capabilities.PROJECTILE_ABSORPTION] = jelly.capability,
})

return jelly
