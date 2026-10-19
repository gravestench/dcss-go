local order = require("constants.damage_reaction_order")
local restrictions = require("constants.safety_restrictions")
local mutations = require("ids.mutations")
local safety = require("policy.character.damage_safety")
local reactions = require("policy.combat.player_damage_reactions")
local levels = require("policy.mutations.levels")
local threat = require("policy.mutations.effects.damage.threat")

local read_safety = {}

-- A damage event can interrupt reading when the relevant mutation is active.
-- Example: read-safety reacts to a threatening hit through the same threshold helper as drink-safety.
function read_safety.on_damage(ctx, player, damage)
    local level = levels.effective(ctx, player,
        mutations.MUT_READ_SAFETY)

    if level > 0 and threat.triggered(ctx, player, damage, level) then
        safety.apply(ctx, player, restrictions.SCROLLS, damage,
            "You feel threatened and lose the ability to read scrolls!")
    end
end

reactions.add_before(mutations.MUT_READ_SAFETY,
    order.READ_SAFETY, read_safety.on_damage)

return read_safety
