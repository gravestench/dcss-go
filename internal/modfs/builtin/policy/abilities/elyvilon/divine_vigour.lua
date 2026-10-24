-- The five-star power invokes Elyvilon's timed HP and MP enlargement.
-- Resource formulas own the bonus after the ability has paid its cost.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local vigour = require("policy.religion.elyvilon.vigour")

local divine = {}

-- Patron, penance, and rank are checked whenever the menu is displayed.
function divine.available(ctx, player)
    return costs.available(ctx, player, gods.ELYVILON, 5)
end

-- The source forbids a second grant while the old timer is positive.
function divine.prepare(ctx, player)
    if vigour.amount(ctx, player) > 0 then
        return "You have already been granted divine vigour!"
    end
end

-- Success stores and applies the buff before the ordinary six-point
-- piety cost; failure consumes only the committed turn.
function divine.resolve(ctx, player)
    if costs.failed(ctx, player, 80, 4, 25) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    vigour.invoke(ctx, player)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 6))
end

registry.add(abilities.ELYVILON_DIVINE_VIGOUR, {
    name = "Divine Vigour",
    available = divine.available,
    prepare = divine.prepare,
    resolve = divine.resolve,
})

return divine
