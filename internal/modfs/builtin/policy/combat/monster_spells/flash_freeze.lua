local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flash_freeze_rule = require(
    "policy.combat.monster_beams.flash_freeze")
local spells = require("ids.spells")

local flash_freeze = {}
-- Flash Freeze uses beam contact for its cold hit and keeps its range in the catalog profile.
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FLASH_FREEZE)

-- Example: flash_freeze.plan(ctx, caster, foe) with adjacent foe -> entity plan for the cold contact
-- Uses the catalog range before applying its cold contact.
function flash_freeze.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Contact applies cold damage, then the Flash Freeze status to the struck foe.
function flash_freeze.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile,
        plan, flash_freeze_rule)
end

return flash_freeze
