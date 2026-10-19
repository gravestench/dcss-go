-- Eruption uses Upheaval's target footprint and three-die strike but
-- always selects magma, including the chance to leave temporary lava.
-- Source: mon-cast.cc:_mons_upheaval with randomize=false.
local area = require("policy.combat.monster_area.upheaval")
local spells = require("ids.spells")

local effect = {}

-- The same source foe-ratio check accounts for every actor near the cell.
function effect.plan(ctx, caster, foe)
    return area.plan(ctx, caster, foe)
end

-- Keep the source variant fixed while preserving Eruption attribution.
function effect.resolve(ctx, caster, _, _, plan)
    area.resolve(ctx, caster, plan, false, spells.SPELL_ERUPTION)
end

return effect
