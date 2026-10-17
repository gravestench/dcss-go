local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local thorn_volley = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THORN_VOLLEY)

function thorn_volley.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function thorn_volley.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return thorn_volley
