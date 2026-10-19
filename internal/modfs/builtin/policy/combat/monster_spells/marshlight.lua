-- Marshlight uses the source's ordinary foxfire creation, with monster
-- spell power and a monster-owned summon. The foxfire remains a physical
-- actor whose later movement and contact are resolved by ECS systems.
-- Source: mon-cast.cc:_cast_marshlight, spl-summoning.cc:cast_foxfire.
local foxfire = require("policy.magic.effects.summons.foxfire")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local strength = require("policy.combat.monster_summons.strength")

local effect = {}

-- The source lets monsters cast even when no foxfire cell is ultimately
-- available. Keep the plan free of random draws and resolve that at cast time.
function effect.plan(_, caster)
    return self_target.plan(caster)
end

-- Each foxfire stores the caster and Marshlight source spell in its summon
-- component, so restore can continue its attack without a special adapter.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local power = strength.power(ctx, caster, spells.SPELL_MARSHLIGHT)

    foxfire.spawn(ctx, caster, spells.SPELL_MARSHLIGHT, power)
end

return effect
