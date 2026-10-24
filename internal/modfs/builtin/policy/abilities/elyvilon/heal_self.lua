-- Heal Self restores ordinary HP; Death's Door's safety contract forbids
-- healing while that necromantic status is active.
local abilities = require("ids.abilities")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local power = require("policy.magic.power")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")

local healing = {}

-- Elyvilon unlocks personal healing at the third piety star.
function healing.available(ctx, player)
    return costs.available(ctx, player, gods.ELYVILON, 3)
end

-- Full HP and Death's Door reject before the timed command exists.
function healing.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 2) then
        return "You do not have enough magic."
    end

    local health = ctx:get(player, component.HEALTH)

    if health.current >= health.max then
        return "You are already at full health."
    end

    if statuses.death_door_active(ctx, player) then
        return "You can't heal while in death's door."
    end
end

-- Source caps base healing power at 50, then rolls two dice of that
-- size. The successful effect precedes MP and piety payment.
function healing.resolve(ctx, player)
    if costs.failed(ctx, player, 40, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    local trained = power.training(ctx, player,
        skills.SK_INVOCATIONS, 1)
    local strength = math.min(50, 10 + roll.random_divide(ctx,
        trained, 3, streams.RELIGION))
    local amount = strength +
        roll.draw(ctx, streams.RELIGION, strength) +
        roll.draw(ctx, streams.RELIGION, strength)
    local health = ctx:get(player, component.HEALTH)

    health.current = math.min(health.max, health.current + amount)
    ctx:set(player, component.HEALTH, health)
    ctx:emit("religion", "You are healed.")
    costs.spend(ctx, player, 2, costs.piety_cost(ctx, 3))
end

registry.add(abilities.ELYVILON_HEAL_SELF, {
    name = "Heal Self",
    available = healing.available,
    prepare = healing.prepare,
    resolve = healing.resolve,
})

return healing
