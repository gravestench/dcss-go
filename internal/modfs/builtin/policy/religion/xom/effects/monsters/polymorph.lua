-- Xom transforms one nearby body with the ordinary saved polymorph owner.
local catalog = require("policy.catalog")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local events = require("ids.xom_events")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local holiness = require("constants.monster_holiness")
local monster_ids = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local shapeshifter = require("policy.monsters.shapeshifter")
local streams = require("constants.rng_streams")

local effect = {}

-- Monster flags live on the catalog definition, not the actor component.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- The source tests the first mutable, non-firewood body in nearby sight.
-- A target may be friendly; that reverses whether the action strengthens
-- or weakens it, preserving Xom's player-relative notion of helpfulness.
function effect.polymorph_target(ctx, player)
    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        local actor = ctx:get(monster, component.ACTOR)
        local definition = actor and catalog.get("monsters", actor.kind_id)
        local firewood = definition and
            has_flag(definition, flags.STATIONARY) and
            has_flag(definition, flags.NO_THREAT) and
            not groups.tentacles[definition.id] and
            not groups.test_monsters[definition.id]

        if definition and not firewood and
            polymorph.can_actor(ctx, monster) then
            return monster, definition
        end
    end

    return nil
end

-- A rare natural body becomes a persistent shifter before Xom changes it.
-- Marking is separate from the ordinary creation-time attach method so
-- this event gets one relative-power transformation, not two random ones.
local function maybe_make_shifter(ctx, monster, definition, stream)
    if ctx:random(stream, 8) ~= 0 or
        has_flag(definition, flags.GHOST_DEMON) or
        shapeshifter.active(ctx, monster) then
        return
    end

    local natural = false

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.NATURAL then
            natural = true
            break
        end
    end

    if not natural then
        return
    end

    local variant = ctx:random(stream, 3) == 0 and
        monster_ids.MONS_GLOWING_SHAPESHIFTER or
        monster_ids.MONS_SHAPESHIFTER

    shapeshifter.mark(ctx, monster, variant)
end

-- PPT_LESS and PPT_MORE are relative to the monster's actual allegiance,
-- not the event label alone. A friendly body is strengthened by a nominally
-- good event and weakened by a nominally bad one.
local function polymorph_monster(ctx, player, helpful, stream)
    local monster, definition = effect.polymorph_target(ctx, player)

    if not monster then
        return false
    end

    maybe_make_shifter(ctx, monster, definition, stream)

    local strengthen = helpful ~= confusion.hostile(ctx, monster)

    if strengthen then
        return polymorph.more(ctx, monster, definition, stream)
    end

    return polymorph.less(ctx, monster, definition, stream)
end

-- The event label is player-relative; allegiance decides the power window.
function effect.apply(ctx, player, event_id, _, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.GOOD_POLYMORPH then
        return polymorph_monster(ctx, player, true, stream)
    end

    if event_id == events.BAD_POLYMORPH then
        return polymorph_monster(ctx, player, false, stream)
    end

    error("polymorph effect received another Xom event")
end

return effect
