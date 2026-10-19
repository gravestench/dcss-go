-- Wooden Splinterspray uses the same fragment contact and piercing ray
-- owner as Metal Splinters; its definition supplies the distinct formula.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local splinterspray = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPLINTERSPRAY)

-- Save the chosen foe and direction before the monster spends its action.
-- The common planner also avoids a ray through an allied creature.
function splinterspray.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Resolve each contact on the saved ray rather than retargeting after the
-- first hit. Both foes get their own triple-armour roll.
function splinterspray.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return splinterspray
