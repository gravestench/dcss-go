-- Purification is Elyvilon's one-star self-healing power. Source permits
-- it while confused because confusion is one of the ailments it removes.
local abilities = require("ids.abilities")
local cleansing = require("policy.religion.elyvilon.cleansing")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")

local purification = {}

-- Only live, nonpenitent Elyvilon worship grants this menu row.
function purification.available(ctx, player)
    return costs.available(ctx, player, gods.ELYVILON, 1)
end

-- Cure-only invocation should not charge or spend a turn when there is
-- nothing to remove, even if the player can otherwise use the power.
function purification.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 2) then
        return "You do not have enough magic."
    end

    if not cleansing.needed(ctx, player) then
        return "Nothing ails you!"
    end
end

-- Source failure consumes time; success removes every represented
-- ailment before paying the two MP and rolled two-point piety cost.
function purification.resolve(ctx, player)
    if costs.failed(ctx, player, 20, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    cleansing.apply(ctx, player)
    costs.spend(ctx, player, 2, costs.piety_cost(ctx, 2))
end

registry.add(abilities.ELYVILON_PURIFICATION, {
    name = "Purification",
    confusion_ok = true,
    available = purification.available,
    prepare = purification.prepare,
    resolve = purification.resolve,
})

return purification
