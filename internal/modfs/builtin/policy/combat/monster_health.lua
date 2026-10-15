local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")

local monster_health = {}

-- Shared monster HP loss lets mutation effects observe damage actually
-- dealt after petrification, with an explicit source actor.
function monster_health.damage(ctx, target, amount, source)
    local health = ctx:get(target, component.HEALTH)

    if not health then
        error("monster damage target has no health")
    end

    local before = health.current

    if before <= 0 then
        return health, 0
    end

    statuses.wake_hibernating(ctx, target)
    amount = statuses.petrified_damage(ctx, target, amount)

    local dealt = math.min(before, math.max(0, amount))

    health.current = before - dealt
    ctx:set(target, component.HEALTH, health)

    if dealt > 0 and health.current > 0 and source and
        ctx:has(source, component.PLAYER) then
        local hit = {
            target = target,
            damage = dealt,
        }

        effects.trigger(ctx, source, capabilities.AFTER_MONSTER_DAMAGE, hit)
    end

    return health, dealt
end

return monster_health
