local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Iron imps are the rare edge of the source's weighted imp choice.
local kinds = {
    {
        id = monsters.MONS_IRON_IMP,
        weight = 1,
    },

    {
        id = monsters.MONS_SHADOW_IMP,
        weight = 2,
    },

    {
        id = monsters.MONS_WHITE_IMP,
        weight = 2,
    },

    {
        id = monsters.MONS_CRIMSON_IMP,
        weight = 4,
    },
}

-- Imp kind and HD-scaled duration are chosen on resolution; a declined
-- intent must leave the monster spell stream untouched.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- One imp uses the source weighted kind and effective spell HD for expiry.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local degree = math.min(2 + math.floor(hd / 5), 6)
    local kind = choice.weighted(ctx, kinds)

    summons.spawn(ctx, caster, spells.SPELL_CALL_IMP, kind, degree, nil)
end

return effect
