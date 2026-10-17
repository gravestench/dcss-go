local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local spit_lava = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_SPIT_LAVA)

function spit_lava.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function spit_lava.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return spit_lava
