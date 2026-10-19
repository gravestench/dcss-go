-- Stoke Flames creates one ordinary creeping inferno. Its source monster
-- speed, movement, and physical health remain on the summoned ECS actor;
-- the actor death hook resolves the eventual Fire Storm explosion.
-- Source: mon-cast.cc:SPELL_STOKE_FLAMES, mon-explode.cc.
local monsters = require("ids.monsters")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

-- Summoning does not choose a cell until the cast commits.
function effect.plan(_, caster)
    return self_target.plan(caster)
end

-- The source's degree-two abjuration gives the inferno a saved lifetime.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    summons.spawn(ctx, caster, spells.SPELL_STOKE_FLAMES,
        monsters.MONS_CREEPING_INFERNO, 2, nil)
end

return effect
