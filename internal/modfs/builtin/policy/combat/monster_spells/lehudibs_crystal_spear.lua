local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local lehudibs_crystal_spear = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR)

function lehudibs_crystal_spear.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function lehudibs_crystal_spear.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return lehudibs_crystal_spear
