-- Berserk Other goads nearby aligned creatures instead of creating allies.
-- Source: mon-cast.cc:_incite_monsters and _make_monster_angry.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local component = require("constants.component")
local monsters = require("ids.monsters")
local actors = require("policy.combat.monster_area.actors")
local self_target = require("policy.combat.monster_support.self_target")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local INCITEMENT_RADIUS = 3

-- Queen Bee commands only bees; a Moth of Wrath cannot goad another moth.
-- These are source caster rules, not a generic faction restriction.
local function kind_allowed(caster_kind, ally_kind)
    if caster_kind == monsters.MONS_QUEEN_BEE then
        return ally_kind == monsters.MONS_KILLER_BEE or
            ally_kind == monsters.MONS_MELIAI
    end

    return caster_kind ~= monsters.MONS_MOTH_OF_WRATH or
        ally_kind ~= monsters.MONS_MOTH_OF_WRATH
end

-- The incited ally needs its own nearby foe and must be ahead of the caster
-- on that route. Goading a rear guard would merely obstruct the fight.
local function candidate(ctx, caster, ally, caster_position, caster_kind)
    if ally == caster or ctx:has(ally, component.PLAYER) or
        not targets.aligned(ctx, caster, ally) then
        return false
    end

    local actor = ctx:get(ally, component.ACTOR)
    local position = ctx:get(ally, component.POSITION)

    if not actor or not position or
        not kind_allowed(caster_kind, actor.kind_id) then
        return false
    end

    local foe = targets.nearest(ctx, ally, position, 7)

    if not foe or not allegiance.needs_berserk(ctx, ally, foe) then
        return false
    end

    local victim = ctx:get(foe, component.POSITION)
    local ally_distance = math.max(math.abs(victim.x - position.x),
        math.abs(victim.y - position.y))
    local caster_distance = math.max(
        math.abs(victim.x - caster_position.x),
        math.abs(victim.y - caster_position.y))

    return ally_distance <= caster_distance
end

-- Planning scans visible allies but consumes no one-in-three continuation
-- draw. The target is the caster because resolution chooses live recipients.
function effect.plan(ctx, caster)
    local position = ctx:get(caster, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)

    if not position or not actor then
        return nil
    end

    for _, ally in ipairs(actors.los(ctx, caster, INCITEMENT_RADIUS)) do
        if candidate(ctx, caster, ally, position, actor.kind_id) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Each goaded ally starts the shared saved frenzy. The source usually
-- stops after one success, but a one-in-three draw can continue the chant.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local position = ctx:get(caster, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)

    if not position or not actor then
        return
    end

    local goaded = 0

    for _, ally in ipairs(actors.los(ctx, caster, INCITEMENT_RADIUS)) do
        if candidate(ctx, caster, ally, position, actor.kind_id) then
            allegiance.start_berserk(ctx, ally)
            goaded = goaded + 1

            if ctx:random(streams.MONSTER_SPELL,
                3 * goaded) ~= 0 then
                return
            end
        end
    end
end

return effect
