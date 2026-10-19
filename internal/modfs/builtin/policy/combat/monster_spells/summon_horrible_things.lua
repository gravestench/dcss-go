local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- The horrible-thing count and kinds are later draws; no foe cell
-- is needed because all arrivals surround the caster.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Each of three to five things independently has a one-in-four chance to be tentacled.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 3 + roll.spell(ctx, 3)
    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        local kind = monsters.MONS_ABOMINATION_LARGE

        if roll.spell(ctx, 4) == 0 then
            kind = monsters.MONS_TENTACLED_MONSTROSITY
        end

        summons.spawn(ctx, caster, spells.SPELL_SUMMON_HORRIBLE_THINGS,
            kind, degree, nil)
    end
end

return effect
