local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local magic_dart = {}
-- Magic Dart uses its auto-hit profile through shared beam resolution.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MAGIC_DART)

-- Example: magic_dart.plan(ctx, caster, foe) with visible foe -> entity plan for an automatic-hit spell
-- Uses an auto-hit profile through beam resolution.
function magic_dart.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The auto-hit profile bypasses ordinary accuracy while keeping shared damage handling.
function magic_dart.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return magic_dart
