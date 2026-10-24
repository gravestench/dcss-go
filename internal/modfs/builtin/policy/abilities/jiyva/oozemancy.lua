-- Oozemancy makes nearby source wall classes temporarily acidic. The
-- saved terrain owner and Jiyva power clock resolve subsequent actions.
local abilities = require("ids.abilities")
local channels = require("constants.message_channels")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local oozemancy = require("policy.religion.jiyva.oozemancy")
local powers = require("policy.religion.jiyva.powers")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local ability = {}

-- Source rank two and current worship are required before the power enters
-- the ability menu or accepts a command.
function ability.available(ctx, player)
    return costs.available(ctx, player, gods.JIYVA, 2)
end

-- Already active or wall-free use aborts before timing and RNG. A
-- temporary wall from another source is not eligible for replacement.
function ability.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 3) then
        return "You do not have enough magic."
    end

    if powers.oozemancy_active(ctx, player) then
        return "You are already calling forth ooze!"
    end

    if #oozemancy.walls(ctx, player) == 0 then
        return "There are no walls around you to affect."
    end

    return nil
end

-- Source failure spends the action alone. On success the two-roll piety
-- duration creates temporary terrain and the standard resource cost.
function ability.resolve(ctx, player)
    local walls = oozemancy.walls(ctx, player)

    if #walls == 0 then
        error("Oozemancy lost its eligible walls before commitment")
    end

    if costs.failed(ctx, player, 80, 0, 2) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local bound = math.floor(worship.piety / 8)
    local turns = 10 + roll.average_two(ctx, streams.RELIGION, bound)

    if oozemancy.place(ctx, player, walls, turns) == 0 then
        error("Oozemancy could not place an eligible wall")
    end

    ctx:emit(channels.RELIGION,
        "Slime begins to ooze from the nearby walls!")
    costs.spend(ctx, player, 3, costs.piety_cost(ctx, 8))
end

registry.add(abilities.JIYVA_OOZEMANCY, {
    name = "Oozemancy",
    available = ability.available,
    prepare = ability.prepare,
    resolve = ability.resolve,
})

return ability
