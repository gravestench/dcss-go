-- Trog's two-star Hand owns its rank, failure, and piety cost. The
-- separate saved Hand owner supplies its time and defensive effects.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local hand_state = require("policy.religion.trog.hand")
local registry = require("policy.abilities.registry")

local hand = {}

-- A current patron with no penance is required even when a prior Hand
-- timer is still active and could otherwise be refreshed.
function hand.available(ctx, player)
    return costs.available(ctx, player, gods.TROG, 2)
end

-- The self-targeted power has no free selection or MP requirement.
function hand.prepare()
    return nil
end

-- Source failure is piety-only. A successful action extends the timer
-- before paying the generic two-point piety cost.
function hand.resolve(ctx, player)
    if costs.failed(ctx, player, 75, 0, 1) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    hand_state.invoke(ctx, player)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 2))
end

registry.add(abilities.TROG_HAND, {
    name = "Trog's Hand",
    available = hand.available,
    prepare = hand.prepare,
    resolve = hand.resolve,
})

return hand
