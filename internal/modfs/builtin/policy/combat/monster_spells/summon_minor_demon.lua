local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local demons = require("policy.combat.monster_summons.demons")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local spells = require("ids.spells")

local effect = {}

-- Lesser demon identities are independent cast-time draws; planning
-- records only the caster whose allegiance they inherit.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Each lesser demon is drawn separately after the source count roll.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, 3)
    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_MINOR_DEMON,
            demons.tier(ctx, 5), degree, nil)
    end
end

return effect
