local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local drakes = require("policy.combat.monster_summons.drakes")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Drake identities are preselected during resolution before any
-- placement, while the plan records only their caster.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source picks all drake kinds before placement; a blocked cell cannot alter later picks.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)
    local degree = math.min(2 + math.floor(hd / 10), 6)
    local kinds = {}

    for _ = 1, count do
        kinds[#kinds + 1] = drakes.pick(ctx)
    end

    for _, kind in ipairs(kinds) do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_DRAKES,
            kind, degree, nil)
    end
end

return effect
