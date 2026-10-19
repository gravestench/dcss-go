-- Upheaval chooses one of four source blast flavours after its selected
-- cell is committed. The shared area owner handles the shuffled cells,
-- source AC rules, temporary lava, and storm clouds.
-- Source: mon-cast.cc:_mons_upheaval.
local area = require("policy.combat.monster_area.upheaval")
local spells = require("ids.spells")

local effect = {}

-- Evaluate allies and enemies in the chosen footprint before casting.
function effect.plan(ctx, caster, foe)
    return area.plan(ctx, caster, foe)
end

-- The source variant roll belongs to resolution, so a refused cast does
-- not select and consume a blast flavour.
function effect.resolve(ctx, caster, _, _, plan)
    area.resolve(ctx, caster, plan, true, spells.SPELL_UPHEAVAL)
end

return effect
