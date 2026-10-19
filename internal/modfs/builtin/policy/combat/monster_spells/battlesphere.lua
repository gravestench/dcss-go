-- Monster Battlesphere creates one saved construct. The shared sphere policy
-- owns its later charge, duration, and response to the caster's conjurations.
-- Source: mon-cast.cc:SPELL_BATTLESPHERE, spl-summoning.cc.
local component = require("constants.component")
local self_target = require("policy.combat.monster_support.self_target")
local sphere = require("policy.magic.effects.summons.battlesphere")
local spells = require("ids.spells")
local strength = require("policy.combat.monster_summons.strength")

local effect = {}

-- A second sphere would replace no source behavior. Keep the AI from
-- spending a turn on this cast while its original construct still exists.
function effect.plan(ctx, caster)
    for _, entity in ipairs(ctx:query({
        component.SUMMON,
        component.SUMMON_BATTLESPHERE,
    })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon.owner == caster then
            return nil
        end
    end

    return self_target.plan(caster)
end

-- The source uses six power per effective spell HD and caps the cast at
-- 200 before the shared policy rolls lifetime, charges, and construct HD.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local power = math.min(200,
        strength.power(ctx, caster, spells.SPELL_BATTLESPHERE))

    sphere.spawn(ctx, caster, power)
end

return effect
