local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local displacement = require("policy.combat.monster_beams.displacement")
local spells = require("ids.spells")

local harpoon_shot = {}
-- Harpoon Shot runs a pull hook after the beam lands, so movement depends on a successful hit.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_HARPOON_SHOT)

-- Example: harpoon_shot.plan(ctx, caster, foe) with clear ray -> entity plan for a possible post-hit pull
-- Records a target pulled only after a successful hit.
function harpoon_shot.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Pull uses actual dealt damage and incoming direction from the landed harpoon.
function harpoon_shot.after_hit(ctx, caster, defender, _, outcome, incoming)
    displacement.pull(ctx, caster, defender, outcome.damage, incoming)
end

-- A landed harpoon invokes the pull hook after ordinary beam contact.
function harpoon_shot.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, harpoon_shot)
end

return harpoon_shot
