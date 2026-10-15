local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local items = require("ids.items")
local potions = require("policy.potions")
local transition = require("policy.mutations.transition")
local physiology = require("policy.mutations.physiology")

local effect = {}

function effect.can_quaff(ctx, player)
    if not physiology.can_safely_mutate(ctx, player) then
        if physiology.can_safely_mutate(ctx, player, false) then
            return "You cannot mutate at present."
        end

        return "You cannot mutate."
    end
end

-- Source: potion.cc:PotionMutation::effect. Both count rolls precede the
-- removal and addition loops; resistance can block each attempt.
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

potions.register(items.POT_MUTATION, effect)

return effect
