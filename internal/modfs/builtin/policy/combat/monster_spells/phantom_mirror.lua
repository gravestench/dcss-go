-- Rakshasa mirrors one nearby ordinary ally. The clone owner copies the
-- selected monster; this spell only decides whether a cast is useful.
-- Source: mon-cast.cc:SPELL_PHANTOM_MIRROR.
local component = require("constants.component")
local mirror = require("policy.combat.monster_summons.mirror")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- A mirror cannot mirror again, and an ordinary caster needs an eligible
-- aligned ally in sight before it spends a spell action.
function effect.plan(ctx, caster)
    if ctx:has(caster, component.SUMMON_MIRROR) or
        #mirror.allies(ctx, caster) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- Re-evaluate live allies at resolution because one may have died or moved
-- since planning. Source chooses uniformly among eligible nearby allies.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local allies = mirror.allies(ctx, caster)

    if #allies == 0 then
        return
    end

    local selected = allies[ctx:random(streams.MONSTER_SPELL,
        #allies) + 1]

    mirror.spawn(ctx, caster, selected,
        spells.SPELL_PHANTOM_MIRROR, 100, nil)
end

return effect
