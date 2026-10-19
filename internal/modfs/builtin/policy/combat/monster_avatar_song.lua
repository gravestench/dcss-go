-- Theory of operation: the avatar owns a continuing song after its cast.
-- Each avatar action may pull its beholder and call drowned souls; silence
-- or incapacity interrupts it. Without a visible audience, its saved timer
-- decays until the song ends. Source: mon-ench.cc.
-- Example: avatar_song.start(ctx, caster, player) stores the singer's
-- status; avatar_song.tick(ctx, caster, 10) performs one later pulse.
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local invisibility = require("policy.potions.invisibility")
local mesmerism = require("policy.character.player_mesmerism")
local pull = require("policy.combat.monster_avatar_song.pull")
local souls = require("policy.combat.monster_avatar_song.souls")
local senses = require("policy.character.senses")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")

local song = {}
local INITIAL_AUT = 70
local SIGHT_RADIUS = 7

-- Beginning a new song records the audience's location. Recasting during
-- an active song does not restart its timer or repeat its first-call notice.
function song.start(ctx, caster, player)
    if ctx:has(caster, component.MONSTER_AVATAR_SONG) then
        return
    end

    local position = ctx:get(player, component.POSITION)

    ctx:add(caster, component.MONSTER_AVATAR_SONG, {
        remaining_aut = INITIAL_AUT,
        called = false,
        last_player_x = position.x,
        last_player_y = position.y,
        last_level_id = position.level_id,
    })
end

-- A player silence field can interrupt a nearby avatar even if the caster
-- has no separate mute component. The source also stops on incapacity.
local function interrupted(ctx, caster, player, origin)
    if ctx:has(caster, component.MONSTER_MUTE) or
        ctx:has(caster, component.PARALYSIS) then
        return true
    end

    local confusion = ctx:get(caster, component.MONSTER_CONFUSION)
    local stasis = ctx:get(caster, component.MONSTER_STASIS)
    local fear = ctx:get(caster, component.MONSTER_MASS_ENCHANT)
    return confusion and confusion.remaining_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrified_aut > 0) or
        fear and fear.fear_aut > 0 or
        silence.at(ctx, origin.level_id, origin.x, origin.y)
end

-- The source remembers whether the player approached voluntarily after
-- the previous pulse. It avoids a second forced step on that same turn.
local function approached(state, listener, origin)
    if state.last_level_id ~= listener.level_id then
        return false
    end

    local before = math.max(math.abs(state.last_player_x - origin.x),
        math.abs(state.last_player_y - origin.y))
    local after = math.max(math.abs(listener.x - origin.x),
        math.abs(listener.y - origin.y))

    return after < before
end

-- Each active caster pulse rechecks audience and terrain. A song without
-- line of sight ages; a visible audience keeps it alive until interrupted.
function song.tick(ctx, caster, elapsed_aut)
    local state = ctx:get(caster, component.MONSTER_AVATAR_SONG)
    local player = ctx:player()
    local origin = ctx:get(caster, component.POSITION)

    if not state or not player or not origin then
        return
    end

    if interrupted(ctx, caster, player, origin) then
        ctx:remove(caster, component.MONSTER_AVATAR_SONG)

        if senses.player_sees_actor(ctx, caster) then
            ctx:emit(channels.SPELL,
                "The " .. display.name(ctx, caster) ..
                    "'s song is interrupted.")
        end

        return
    end

    local listener = ctx:get(player, component.POSITION)
    local audience = listener and
        listener.level_id == origin.level_id and
        invisibility.visible_to(ctx, player, caster) and
        ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, listener.x, listener.y)

    if audience then
        if mesmerism.beheld_by(ctx, player, caster) and
            ctx:random(streams.MONSTER_SPELL, 2) == 0 and
            not approached(state, listener, origin) then
            pull.apply(ctx, caster, player)
        end

        souls.apply(ctx, caster, state)
        listener = ctx:get(player, component.POSITION)
        state.last_player_x = listener.x
        state.last_player_y = listener.y
        state.last_level_id = listener.level_id
    else
        state.remaining_aut = math.max(0,
            state.remaining_aut - elapsed_aut)
    end

    if state.remaining_aut == 0 then
        ctx:remove(caster, component.MONSTER_AVATAR_SONG)
    else
        ctx:set(caster, component.MONSTER_AVATAR_SONG, state)
    end
end

return song
