-- Theory of operation: the player keeps one saved list of monsters drawing
-- its attention. Casts add or refresh a beholder; movement asks whether a
-- destination increases distance; each player action prunes invalid sources
-- and ages the timer. Losing the final source starts temporary immunity.
-- Source: behold.cc, movement.cc, and duration-data.h.
-- Example: mesmerism.blocked(ctx, player, from, farther_cell) returns the
-- siren whose song prevents that step; a closer step remains available.
local component = require("constants.component")
local channels = require("constants.message_channels")
local display = require("policy.combat.monster_support.display")
local invisibility = require("policy.potions.invisibility")
local monster_book = require("policy.combat.monster_spellbook")
local rage = require("policy.character.rage")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local mesmerism = {}
local SIGHT_RADIUS = 7
local INITIAL_MIN_TURNS = 7
local INITIAL_SPAN_TURNS = 9
local REFRESH_MIN_TURNS = 5
local REFRESH_SPAN_TURNS = 4
local MAX_BASE_AUT = 150
local IMMUNE_MIN_TURNS = 21
local IMMUNE_SPAN_TURNS = 20

-- A transformed monster cannot keep a beholder effect if its new kind no
-- longer has the song or spell. Read the live book, including vault override.
local function can_mesmerise(ctx, source)
    local book = monster_book.for_actor(ctx, source)

    if not book then
        return false
    end

    for _, slot in ipairs(book.slots) do
        if slot.spell_id == spells.SPELL_MESMERISE or
            slot.spell_id == spells.SPELL_SIREN_SONG or
            slot.spell_id == spells.SPELL_AVATAR_SONG then
            return true
        end
    end

    return false
end

-- A singer or spellcaster can be heard across an obstructed cell. Source
-- incapacity or player Silence still makes an attempted song pointless.
function mesmerism.audible(ctx, player, source)
    if not ctx:has(source, component.ACTOR) or
        not targets.enemy(ctx, source, player) or
        not can_mesmerise(ctx, source) then
        return false
    end

    local health = ctx:get(source, component.HEALTH)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(source, component.POSITION)
    local confusion = ctx:get(source, component.MONSTER_CONFUSION)
    local stasis = ctx:get(source, component.MONSTER_STASIS)
    local allegiance = ctx:get(source, component.MONSTER_ALLEGIANCE)
    local fear = ctx:get(source, component.MONSTER_MASS_ENCHANT)
    local silence = statuses.silence_radius(ctx, player)

    if not health or health.current <= 0 or
        not origin or not position or
        origin.level_id ~= position.level_id or
        silence >= 0 or
        ctx:has(source, component.MONSTER_MUTE) or
        ctx:has(source, component.PARALYSIS) or
        confusion and confusion.remaining_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrified_aut > 0) or
        allegiance and allegiance.frenzy_aut > 0 or
        fear and fear.fear_aut > 0 then
        return false
    end

    return math.max(math.abs(origin.x - position.x),
        math.abs(origin.y - position.y)) <= SIGHT_RADIUS
end

-- Retaining an actual beholder additionally needs mutual cell sight. An
-- unseen song may be heard without creating a new movement restriction.
function mesmerism.possible(ctx, player, source)
    if not mesmerism.audible(ctx, player, source) or
        not invisibility.visible_to(ctx, player, source) then
        return false
    end

    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(source, component.POSITION)

    return ctx:visible(origin.level_id, origin.x, origin.y,
        SIGHT_RADIUS, position.x, position.y) and
        ctx:visible_no_trans(origin.level_id, position.x, position.y,
            SIGHT_RADIUS, origin.x, origin.y)
end

-- A new direct mesmerism needs a perceivable caster; a singing source may
-- still be heard when unseen, but cannot add a new beholder until seen.
function mesmerism.can_start(ctx, player, source, require_seen,
    allow_rage)
    if not mesmerism.possible(ctx, player, source) or
        not allow_rage and rage.active(ctx, player) then
        return false
    end

    return not require_seen or
        senses.player_sees_actor(ctx, source) or
        mesmerism.beheld_by(ctx, player, source)
end

-- Only a live listed source constrains movement. The timer alone is not a
-- beholder and the immunity interval must not restrict the player.
function mesmerism.beheld_by(ctx, player, source)
    local state = ctx:get(player, component.PLAYER_MESMERISM)

    if not state or state.remaining_aut <= 0 then
        return false
    end

    for _, existing in ipairs(state.sources) do
        if existing == source and mesmerism.possible(ctx, player, source) then
            return true
        end
    end

    return false
end

-- Add one specific source and refresh the shared duration without storing
-- the same entity twice. This policy owns the status, not the spell message.
function mesmerism.apply(ctx, player, source)
    local state = ctx:get(player, component.PLAYER_MESMERISM)
    local fresh = not state or state.remaining_aut <= 0

    state = state or {
        remaining_aut = 0,
        immune_aut = 0,
        sources = {},
    }

    if fresh then
        state.remaining_aut = (INITIAL_MIN_TURNS +
            roll.draw(ctx, streams.MONSTER_SPELL,
                INITIAL_SPAN_TURNS)) * 10
        state.sources = {}
    else
        state.remaining_aut = math.min(MAX_BASE_AUT,
            state.remaining_aut + (REFRESH_MIN_TURNS +
                roll.draw(ctx, streams.MONSTER_SPELL,
                    REFRESH_SPAN_TURNS)) * 10)
    end

    state.immune_aut = 0

    local found = false

    for _, existing in ipairs(state.sources) do
        found = found or existing == source
    end

    if not found then
        state.sources[#state.sources + 1] = source
    end

    if ctx:has(player, component.PLAYER_MESMERISM) then
        ctx:set(player, component.PLAYER_MESMERISM, state)
    else
        ctx:add(player, component.PLAYER_MESMERISM, state)
    end

    if fresh then
        ctx:emit(channels.SPELL,
            "You are mesmerised by the " .. display.name(ctx, source) .. "!")
    end
end

-- Check the same Chebyshev distance as source grid_distance. Moving toward
-- one beholder is legal even if another remains at the same distance.
function mesmerism.blocked(ctx, player, origin, destination)
    local state = ctx:get(player, component.PLAYER_MESMERISM)

    if not state or state.remaining_aut <= 0 then
        return nil
    end

    for _, source in ipairs(state.sources) do
        if mesmerism.possible(ctx, player, source) then
            local position = ctx:get(source, component.POSITION)
            local before = math.max(math.abs(origin.x - position.x),
                math.abs(origin.y - position.y))
            local after = math.max(math.abs(destination.x - position.x),
                math.abs(destination.y - position.y))

            if after > before then
                return source
            end
        end
    end

    return nil
end

-- Stair travel cannot break an active beholder's hold even when the stair
-- occupies the player's current cell and has no movement destination.
function mesmerism.any(ctx, player)
    local state = ctx:get(player, component.PLAYER_MESMERISM)

    if not state or state.remaining_aut <= 0 then
        return nil
    end

    for _, source in ipairs(state.sources) do
        if mesmerism.possible(ctx, player, source) then
            return source
        end
    end

    return nil
end

-- A stale beholder ends the effect before its nominal duration. The short
-- immunity is saved on the same component and decremented on later actions.
function mesmerism.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.PLAYER_MESMERISM)

    if not state then
        return
    end

    if state.remaining_aut > 0 then
        local retained = {}

        for _, source in ipairs(state.sources) do
            if mesmerism.possible(ctx, player, source) then
                retained[#retained + 1] = source
            end
        end

        state.sources = retained
        state.remaining_aut = math.max(0,
            state.remaining_aut - elapsed_aut)

        if state.remaining_aut == 0 or #retained == 0 then
            state.remaining_aut = 0
            state.sources = {}
            state.immune_aut = (IMMUNE_MIN_TURNS +
                roll.draw(ctx, streams.MONSTER_SPELL,
                    IMMUNE_SPAN_TURNS)) * 10
            ctx:emit(channels.DURATION,
                "You are no longer entranced.")
        end
    else
        state.immune_aut = math.max(0,
            state.immune_aut - elapsed_aut)
    end

    if state.immune_aut == 0 and state.remaining_aut == 0 then
        ctx:remove(player, component.PLAYER_MESMERISM)
    else
        ctx:set(player, component.PLAYER_MESMERISM, state)
    end
end

return mesmerism
