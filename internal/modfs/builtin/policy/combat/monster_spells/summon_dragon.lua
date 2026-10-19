local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Each power band has its own uniformly selected source dragon types.
local high = {
    monsters.MONS_GOLDEN_DRAGON,
    monsters.MONS_QUICKSILVER_DRAGON,
}

local middle = {
    monsters.MONS_IRON_DRAGON,
    monsters.MONS_SHADOW_DRAGON,
    monsters.MONS_STORM_DRAGON,
}

local low = {
    monsters.MONS_FIRE_DRAGON,
    monsters.MONS_ICE_DRAGON,
}

-- Dragon tier and possible second low-tier dragon are cast-time
-- choices, so planning records their summoner only.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The two one-in-six upgrades run in source order; low dragons can double.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster,
        spells.SPELL_SUMMON_DRAGON)
    local chance = roll.spell(ctx, power)
    local kind

    if chance >= 80 or roll.spell(ctx, 6) == 0 then
        kind = choice.uniform(ctx, high)
    elseif chance >= 40 or roll.spell(ctx, 6) == 0 then
        kind = choice.uniform(ctx, middle)
    else
        kind = choice.uniform(ctx, low)
    end

    local count = 1

    if power >= 100 and
        (kind == monsters.MONS_FIRE_DRAGON or
            kind == monsters.MONS_ICE_DRAGON) then
        count = 2
    end

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_SUMMON_DRAGON,
            kind, 6, nil)
    end
end

return effect
