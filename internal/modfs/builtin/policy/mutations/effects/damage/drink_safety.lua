local order = require("constants.damage_reaction_order")
local restrictions = require("constants.safety_restrictions")
local mutations = require("ids.mutations")
local safety = require("policy.character.damage_safety")
local reactions = require("policy.combat.player_damage_reactions")
local levels = require("policy.mutations.levels")
local threat = require("policy.mutations.effects.damage.threat")

local drink_safety = {}

-- A damage event can interrupt drinking when the relevant mutation is active.
-- Example: threatening damage activates the drink-safety mutation only after threat.triggered approves it.
function drink_safety.on_damage(ctx, player, damage)
    local level = levels.effective(ctx, player,
        mutations.MUT_DRINK_SAFETY)

    if level > 0 and threat.triggered(ctx, player, damage, level) then
        safety.apply(ctx, player, restrictions.POTIONS, damage,
            "You feel threatened and lose the ability to drink potions!")
    end
end

reactions.add_before(mutations.MUT_DRINK_SAFETY,
    order.DRINK_SAFETY, drink_safety.on_damage)

return drink_safety
