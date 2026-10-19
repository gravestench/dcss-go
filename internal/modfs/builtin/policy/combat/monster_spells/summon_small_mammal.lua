local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local choice = require("policy.combat.monster_summons.choice")
local roll = require("policy.combat.roll")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Source rats are chosen uniformly only when the one-in-three bat draw
-- misses. Keep that second draw inside the branch to preserve RNG order.
local rats = {
    monsters.MONS_QUOKKA,
    monsters.MONS_RIVER_RAT,
    monsters.MONS_RAT,
}

-- The mammal count and bat choice are cast-time draws, so planning only
-- binds the summoner before any of those draws occur.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Each attempted small mammal makes its own bat-or-rat choice.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local count = 1 + roll.spell(ctx, 3)

    for _ = 1, count do
        local kind = monsters.MONS_BAT

        if roll.spell(ctx, 3) ~= 0 then
            kind = choice.uniform(ctx, rats)
        end

        summons.spawn(ctx, caster, spells.SPELL_SUMMON_SMALL_MAMMAL,
            kind, 5, nil)
    end
end

return effect
