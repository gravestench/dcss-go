-- Slimify charges a future successful primary melee contact. Its saved
-- timer and on-hit transformation live in Jiyva's focused religion owner.
local abilities = require("ids.abilities")
local channels = require("constants.message_channels")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local powers = require("policy.religion.jiyva.powers")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local ability = {}

-- Source rank four controls both the menu and committed action gate.
function ability.available(ctx, player)
    return costs.available(ctx, player, gods.JIYVA, 4)
end

-- The effect is prepared on the player, without a target or a second
-- prompt. MP is checked before creating an action that consumes time.
function ability.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 5) then
        return "You do not have enough magic."
    end

    return nil
end

-- Source random2avg(piety/4,2) gives the duration. A failure cannot
-- grant the on-hit charge or spend the MP and piety costs.
function ability.resolve(ctx, player)
    if costs.failed(ctx, player, 90, 0, 2) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local bound = math.floor(worship.piety / 4)
    local turns = 3 + roll.average_two(ctx, streams.RELIGION, bound)

    powers.start_slimify(ctx, player, turns)
    ctx:emit(channels.DURATION,
        "A thick mucus forms on your weapon and hands.")
    costs.spend(ctx, player, 5, costs.piety_cost(ctx, 10))
end

registry.add(abilities.JIYVA_SLIMIFY, {
    name = "Slimify",
    available = ability.available,
    prepare = ability.prepare,
    resolve = ability.resolve,
})

return ability
