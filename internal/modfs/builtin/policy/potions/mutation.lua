local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local item_ids = require("ids.items")
local potions = require("policy.potions")
local transition = require("policy.mutations.transition")

local effect = {}

-- Source: potion.cc:PotionMutation::effect. The count rolls happen before
-- either loop, and every attempt may be blocked by mutation resistance.
function effect.apply(ctx, player)
    ctx:emit("quaff", "You feel extremely strange.")

    local remove_count = 2 + ctx:random("potion", 2)
    local add_count = 1 + ctx:random("potion", 3)

    for _ = 1, remove_count do
        transition.remove_random(ctx, player, choices.ANY, false)
    end

    for _ = 1, add_count do
        transition.grant_random(ctx, player, choices.ANY,
            classes.ACQUIRED, false)
    end

    if ctx:random("potion", 2) == 0 then
        transition.grant_random(ctx, player, choices.GOOD,
            classes.ACQUIRED, false)
    end
end

potions[item_ids.POT_MUTATION] = effect.apply

return effect
