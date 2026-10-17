local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flash_freeze_rule = require(
    "policy.combat.monster_beams.flash_freeze")
local spells = require("ids.spells")

local flash_freeze = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FLASH_FREEZE)

function flash_freeze.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

function flash_freeze.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile,
        plan, flash_freeze_rule)
end

return flash_freeze
