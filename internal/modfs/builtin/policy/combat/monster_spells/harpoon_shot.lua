local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local displacement = require("policy.combat.monster_beams.displacement")
local spells = require("ids.spells")

local harpoon_shot = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_HARPOON_SHOT)

function harpoon_shot.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function harpoon_shot.after_hit(ctx, caster, defender, _, outcome, incoming)
    displacement.pull(ctx, caster, defender, outcome.damage, incoming)
end

function harpoon_shot.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, harpoon_shot)
end

return harpoon_shot
