local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local magic_dart = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MAGIC_DART)

function magic_dart.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function magic_dart.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return magic_dart
