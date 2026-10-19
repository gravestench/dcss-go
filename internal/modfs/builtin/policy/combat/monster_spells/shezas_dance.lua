local boons = require("policy.combat.monster_support.boons")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local weapons = require("policy.combat.monster_summons.dancing_weapons")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

function effect.plan(_, caster)
    return self_target.plan(caster)
end

-- mon-cast.cc:_mons_summon_dancing_weapons creates 2..4 degree-three
-- weapons, then hastes each successfully placed creature.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local count = 2 + ctx:random(streams.MONSTER_SPELL, 3)
    local position = ctx:get(caster, component.POSITION)

    for _ = 1, count do
        local creature = summons.spawn(ctx, caster,
            spells.SPELL_SHEZAS_DANCE, monsters.MONS_DANCING_WEAPON, 3)

        if creature then
            weapons.equip(ctx, creature, position.level_id)
            boons.haste(ctx, creature, duration.beneficial(ctx, creature))
        end
    end
end

return effect
