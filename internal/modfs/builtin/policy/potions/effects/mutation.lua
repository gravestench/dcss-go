local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local items = require("ids.items")
local potions = require("policy.potions")
local transition = require("policy.mutations.transition")
local physiology = require("policy.mutations.physiology")
local component = require("constants.component")
local gods = require("constants.gods")
local kinds = require("constants.religion_conduct")
local conduct = require("policy.religion.conduct")

local effect = {}

-- Physiology and current form gate mutation before any removal or addition rolls.
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
-- Example: a Mutation potion rolls separate removal and addition counts on the potion stream.
function effect.apply(ctx, player, known)
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

    -- Zin judges a deliberate known mutation potion after its effects.
    -- An unknown potion receives the source's one-time forgiveness.
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship and worship.god_id == gods.ZIN then
        conduct.record(ctx, {
            id = kinds.DELIBERATE_MUTATING,
            level = 15,
            known = known ~= false,
        })
    end
end

potions.register(items.POT_MUTATION, effect)

return effect
