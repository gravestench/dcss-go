local order = require("constants.damage_reaction_order")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_damage_reactions")
local stat_loss = require("policy.character.stat_loss")
local levels = require("policy.mutations.levels")

local deterioration = {}

-- Source: ouch.cc:_deteriorate draws the level-in-four chance before
-- checking whether the damage exceeds one tenth of maximum HP.
-- Example: damage exceeding one tenth of max HP can trigger Deterioration after its level-based roll.
function deterioration.on_damage(ctx, player, damage)
    local level = levels.effective(ctx, player,
        mutations.MUT_DETERIORATION)

    if level <= 0 then
        return
    end

    local triggered = ctx:random("mutation", 4) < level
    local health = ctx:get(player, "core.health")

    if triggered and damage > health.max / 10 then
        ctx:emit("warning", "Your body deteriorates!")
        stat_loss.drain_random(ctx, player)
    end
end

reactions.add(mutations.MUT_DETERIORATION,
    order.DETERIORATION, deterioration.on_damage)

return deterioration
