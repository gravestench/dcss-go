-- The Iron Elemental's splinters use the shared piercing ray path. Its
-- profile selects triple armour; this effect only chooses when to aim it.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local spells = require("ids.spells")

local metal_splinters = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_METAL_SPLINTERS)

-- Aim at the current foe before committing a spell action. A blocked path
-- declines here so the monster can choose another action.
function metal_splinters.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Follow the saved ray through each contact. The fragment contact owner
-- rolls armour for every defender, so this spell needs no per-target loop.
function metal_splinters.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan)
end

return metal_splinters
