-- cloud.cc:CLOUD_CHAOS applies one weighted chaos enchantment on half of
-- exposures. The player and monster paths use their normal saved statuses.
local categories = require("constants.catalog")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local slow = require("policy.character.slow")
local rage = require("policy.character.rage")
local petrification = require("policy.combat.player_petrification")

local chaos = {}

-- Cap the player haste timer rather than stacking a second duration.
local function haste(ctx, player)
    local state = ctx:get(player, component.DURATIONS)
    state.haste_aut = math.min(400, state.haste_aut + 100)
    ctx:set(player, component.DURATIONS, state)
end

-- Add a bounded Might duration on the existing player state.
local function might(ctx, player)
    local state = ctx:get(player, component.DURATIONS)
    state.might_aut = math.min(800, state.might_aut + 100)
    ctx:set(player, component.DURATIONS, state)
end

-- Refresh Agility to at least ten turns without shortening a longer effect.
local function agility(ctx, player)
    local state = ctx:get(player, component.AGILITY)

    if state then
        state.remaining_aut = math.max(state.remaining_aut, 100)
        ctx:set(player, component.AGILITY, state)
    else
        ctx:add(player, component.AGILITY, {
            remaining_aut = 100,
        })
    end
end

-- Refresh potion invisibility to at least ten turns on chaos exposure.
local function invisible(ctx, player)
    local state = ctx:get(player, component.POTION_INVISIBILITY)

    if state then
        state.remaining_aut = math.max(state.remaining_aut, 100)
        ctx:set(player, component.POTION_INVISIBILITY, state)
    else
        ctx:add(player, component.POTION_INVISIBILITY, {
            remaining_aut = 100,
        })
    end
end

-- Chaos paralysis extends an existing status only when its timer is shorter.
local function paralyze(ctx, player)
    local state = ctx:get(player, component.PLAYER_PARALYSIS)

    if state then
        state.remaining_aut = math.max(state.remaining_aut, 20)
        ctx:set(player, component.PLAYER_PARALYSIS, state)
    else
        ctx:add(player, component.PLAYER_PARALYSIS, {
            remaining_aut = 20,
        })
    end
end

-- Delegate slowing so resistance and duration rules stay shared.
local function slow_player(ctx, player)
    slow.apply(ctx, player, 10)
end

-- Use the clouds stream when chaos starts berserk rage.
local function rage_player(ctx, player)
    rage.begin(ctx, player, streams.CLOUDS)
end

-- Exclude berserk from the draw when current state forbids it.
local function can_rage(ctx, player)
    return ctx:get(player, component.PLAYER) and
        rage.can_begin(ctx, player)
end

local player_effects = {
    {
        weight = 5,
        apply = rage_player,
        valid = can_rage,
    },
    {
        weight = 10,
        apply = haste,
    },
    {
        weight = 10,
        apply = might,
    },
    {
        weight = 10,
        apply = agility,
    },
    {
        weight = 10,
        apply = invisible,
    },
    {
        weight = 10,
        apply = slow_player,
    },
    {
        weight = 5,
        apply = paralyze,
    },
    {
        weight = 5,
        apply = petrification.apply,
    },
}

-- Ineligible berserk is removed from the weighted table rather than consuming a result that does nothing.
local function apply_player(ctx, actor)
    local total = 0

    for _, effect in ipairs(player_effects) do
        if not effect.valid or effect.valid(ctx, actor) then
            total = total + effect.weight
        end
    end

    local draw = ctx:random(streams.CLOUDS, total)

    for _, effect in ipairs(player_effects) do
        if not effect.valid or effect.valid(ctx, actor) then
            if draw < effect.weight then
                effect.apply(ctx, actor)
                return
            end

            draw = draw - effect.weight
        end
    end
end

-- Monster chaos routes through the shared chaos-brand effect on a live target.
local function apply_monster(ctx, actor)
    local state = ctx:get(actor, component.ACTOR)
    local health = ctx:get(actor, component.HEALTH)

    if not state or not health or health.current <= 0 then
        return
    end

    local hit = {
        defender = actor,
        definition = catalog.get(categories.MONSTERS, state.kind_id),
        health = health,
    }

    local effects = require("policy.combat.player_brands.chaos_effects")
    effects.apply(ctx, hit, streams.CLOUDS)
end

-- Spend a clouds-stream draw before selecting player or monster chaos effects, preserving exposure odds.
-- Example: half of cloud exposures produce no enchantment; the other half uses the clouds RNG stream.
function chaos.apply(ctx, actor)
    if ctx:random(streams.CLOUDS, 2) ~= 0 then
        return 0
    end

    if actor == ctx:player() then
        apply_player(ctx, actor)
    else
        apply_monster(ctx, actor)
    end

    return 0
end

return chaos
