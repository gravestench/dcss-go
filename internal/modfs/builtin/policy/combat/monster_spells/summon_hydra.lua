local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Head count is a cast-time power roll; planning first fixes the
-- caster that owns the resulting Hydra.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The one-in-six cap permits twelve heads; power still gives at least four.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster,
        spells.SPELL_SUMMON_HYDRA)
    local max_heads = roll.spell(ctx, 6) == 0 and 12 or 8
    local rolled_heads = math.floor(roll.spell(ctx, power) / 6)
    local heads = math.max(4, math.min(rolled_heads, max_heads))

    summons.spawn(ctx, caster, spells.SPELL_SUMMON_HYDRA,
        monsters.MONS_HYDRA, 1, nil, {
            heads = heads,
        })
end

return effect
