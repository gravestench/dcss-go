-- Theory of operation: a feared player keeps both the source monsters and
-- remaining duration on one ECS component. The spell adds a source; movement
-- consults it before spending an action; the player tick removes expired or
-- impossible sources. Source: fearmonger.cc and movement.cc.
-- Example: player_fear.blocked(ctx, player, from, closer_cell) returns the
-- monster that prevents moving closer, while a sideways step remains legal.
local component = require("constants.component")
local channels = require("constants.message_channels")
local display = require("policy.combat.monster_support.display")
local holiness = require("policy.character.holiness")
local resistance = require("policy.combat.player_resistance")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local fear = {}
local SIGHT_RADIUS = 7
local INITIAL_FEAR_AUT = 70
local REFRESH_FEAR_AUT = 50
local MAX_BASE_FEAR_AUT = 120
local BONUS_TURNS = 10
local MAX_ENCHANT_POWER = 200

-- The source may have died, moved away, changed allegiance, or become
-- confused after casting. None of these leave a lasting fearmonger.
local function possible(ctx, player, source)
    if not ctx:has(source, component.ACTOR) or
        not targets.enemy(ctx, source, player) then
        return false
    end

    local health = ctx:get(source, component.HEALTH)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(source, component.POSITION)
    local confusion = ctx:get(source, component.MONSTER_CONFUSION)
    local source_fear = ctx:get(source, component.MONSTER_MASS_ENCHANT)
    local stasis = ctx:get(source, component.MONSTER_STASIS)
    local allegiance = ctx:get(source, component.MONSTER_ALLEGIANCE)

    if not health or health.current <= 0 or
        not origin or not position or
        origin.level_id ~= position.level_id or
        ctx:has(source, component.MONSTER_MUTE) or
        ctx:has(source, component.PARALYSIS) or
        confusion and confusion.remaining_aut > 0 or
        source_fear and source_fear.fear_aut > 0 or
        stasis and (stasis.hibernating or stasis.petrified_aut > 0) or
        allegiance and allegiance.frenzy_aut > 0 then
        return false
    end

    return ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
        SIGHT_RADIUS, position.x, position.y) and
        ctx:visible(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, position.x, position.y)
end

-- The source AI can consider any naturally fear-capable player, even when
-- an unseen clarity effect will later prevent the actual cast.
function fear.possible(ctx, player)
    return holiness.natural(ctx, player)
end

-- Clarity prevents actual fear after the spell's willpower attempt.
function fear.eligible(ctx, player)
    return fear.possible(ctx, player) and
        not resistance.clarity(ctx, player)
end

-- Four averaged monster-spell draws extend the initial seven-turn fear.
-- Repeated fear retains old sources and cannot overwrite a longer timer.
local function added_duration(ctx, power)
    local bound = math.floor(math.min(MAX_ENCHANT_POWER, power) / 10)
    local total = 0

    for _ = 1, 4 do
        total = total + roll.draw(ctx, streams.MONSTER_SPELL, bound)
    end

    return 10 * (BONUS_TURNS + math.floor(total / 4))
end

-- Record the specific source so movement can compare distances to that
-- monster. Reapplication refreshes time without duplicating its handle.
function fear.apply(ctx, player, source, power)
    local state = ctx:get(player, component.PLAYER_FEAR)
    local fresh = state == nil

    state = state or {
        remaining_aut = INITIAL_FEAR_AUT,
        sources = {},
    }

    if not fresh then
        state.remaining_aut = math.min(MAX_BASE_FEAR_AUT,
            state.remaining_aut + REFRESH_FEAR_AUT)
    end

    state.remaining_aut = state.remaining_aut +
        added_duration(ctx, power)

    local found = false

    for _, existing in ipairs(state.sources) do
        found = found or existing == source
    end

    if not found then
        state.sources[#state.sources + 1] = source
    end

    if fresh then
        ctx:add(player, component.PLAYER_FEAR, state)
        ctx:emit(channels.SPELL, "You are terrified of the " ..
            display.name(ctx, source) .. "!")
    else
        ctx:set(player, component.PLAYER_FEAR, state)
    end
end

-- An active source can make a melee attempt flinch even when the player
-- remains able to attack; checking only component presence is insufficient.
function fear.afraid_of(ctx, player, source)
    local state = ctx:get(player, component.PLAYER_FEAR)

    if not state or state.remaining_aut <= 0 then
        return false
    end

    for _, existing in ipairs(state.sources) do
        if existing == source and possible(ctx, player, source) then
            return true
        end
    end

    return false
end

-- Source movement.cc blocks only a step that decreases distance to one
-- fearmonger. The command caller turns a blocked step into a free refusal.
function fear.blocked(ctx, player, origin, destination)
    local state = ctx:get(player, component.PLAYER_FEAR)

    if not state or state.remaining_aut <= 0 then
        return nil
    end

    for _, source in ipairs(state.sources) do
        if possible(ctx, player, source) then
            local position = ctx:get(source, component.POSITION)
            local before = math.max(math.abs(origin.x - position.x),
                math.abs(origin.y - position.y))
            local after = math.max(math.abs(destination.x - position.x),
                math.abs(destination.y - position.y))

            if after < before then
                return source
            end
        end
    end

    return nil
end

-- Source validity can end fear before its timer does. The player system
-- prunes each source after an action, then decrements time in aut.
function fear.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.PLAYER_FEAR)

    if not state then
        return
    end

    local retained = {}

    for _, source in ipairs(state.sources) do
        if possible(ctx, player, source) then
            retained[#retained + 1] = source
        end
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)
    state.sources = retained

    if state.remaining_aut == 0 or #retained == 0 then
        ctx:remove(player, component.PLAYER_FEAR)
        ctx:emit(channels.DURATION, "You are no longer terrified.")
    else
        ctx:set(player, component.PLAYER_FEAR, state)
    end
end

return fear
