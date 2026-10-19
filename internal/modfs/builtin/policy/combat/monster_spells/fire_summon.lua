local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Brimstone Fiends are the rarest member of this three-kind source pool.
local kinds = {
    {
        id = monsters.MONS_BALRUG,
        weight = 3,
    },

    {
        id = monsters.MONS_HELLION,
        weight = 2,
    },

    {
        id = monsters.MONS_BRIMSTONE_FIEND,
        weight = 1,
    },
}

-- Fiery demons appear around their caster; the weighted kinds are
-- drawn after a valid intent is committed.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Each fiery demon uses a separate pool draw and the slower ten-HD duration.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)
    local degree = math.min(2 + math.floor(hd / 10), 6)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_FIRE_SUMMON,
            choice.weighted(ctx, kinds), degree, nil)
    end
end

return effect
