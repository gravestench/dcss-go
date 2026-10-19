-- Black Mark grants allied melee monsters a saved on-hit enchantment.
-- Source: mon-cast.cc:_cast_black_mark.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local senses = require("policy.character.senses")
local self_target = require("policy.combat.monster_support.self_target")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7

-- Only an aligned monster with a real melee attack can benefit. The caster
-- does not mark itself, and an already marked ally consumes no new timer.
local function eligible(ctx, caster, target)
    if target == caster or ctx:has(target, component.PLAYER) or
        not targets.aligned(ctx, caster, target) or
        ctx:has(target, component.MONSTER_BLACK_MARK) then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return enfeeble.has_attacks(definition)
end

-- Avoid spending the cast if no current ally can gain a mark.
function effect.plan(ctx, caster)
    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if eligible(ctx, caster, target) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Recheck live recipients after commitment and store each duration on the
-- recipient whose later melee will consume it.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if eligible(ctx, caster, target) then
            ctx:add(target, component.MONSTER_BLACK_MARK, {
                remaining_aut = duration.beneficial(ctx, target),
            })
            if senses.player_sees_actor(ctx, target) then
                ctx:emit(channels.SPELL,
                    "An ally begins absorbing vital energies!")
            end
        end
    end
end

return effect
