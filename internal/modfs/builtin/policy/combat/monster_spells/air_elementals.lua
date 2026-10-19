local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Air elementals belong beside their caster, so the intent
-- selects that actor before the HD-dependent count roll.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Air elementals use the shared HD count and a distinct air kind.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + (hd > 15 and 1 or 0) +
        roll.spell(ctx, math.floor(hd / 7) + 1)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_AIR_ELEMENTALS,
            monsters.MONS_AIR_ELEMENTAL, 3, nil)
    end
end

return effect
