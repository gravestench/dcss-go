-- Yredelemnul can reclaim permanent undead gifts from a follower on the
-- current floor. The god and allegiance live in the existing saved summon
-- record; expiry zero distinguishes a reaped companion from a temporary
-- spell summon without a second marker component.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local holiness = require("constants.monster_holiness")
local monster_stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local souls = {}

-- A gift must be a living, permanent, friendly undead actor owned by the
-- player and credited to Yredelemnul. Bound souls and tentacle segments
-- remain under their own effect owners and are never taken here.
function souls.eligible(ctx, player, entity)
    local state = ctx:get(entity, component.SUMMON)
    local actor = ctx:get(entity, component.ACTOR)
    local health = ctx:get(entity, component.HEALTH)
    local position = ctx:get(entity, component.POSITION)
    local player_position = ctx:get(player, component.POSITION)

    if not state or not actor or not health or
        health.current <= 0 or not position or
        not player_position or
        position.level_id ~= player_position.level_id or
        state.owner ~= player or
        state.source_category ~= categories.GODS or
        state.source_id ~= gods.YREDELEMNUL or
        state.attitude ~= attitudes.FRIENDLY or
        state.expires_aut ~= 0 or
        ctx:has(entity, component.MONSTER_BOUND_SOUL) or
        ctx:has(entity, component.SUMMON_SEGMENT) then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.UNDEAD then
            return true
        end
    end

    return false
end

-- The first eligible soul is always taken. Later gifts face the source's
-- one-in-seen and HD checks, preserving the separate short-circuit draws.
function souls.reclaim(ctx, player)
    local gifts = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        if souls.eligible(ctx, player, entity) then
            gifts[#gifts + 1] = entity
        end
    end

    table.sort(gifts, function(left, right)
        return ctx:id(left) < ctx:id(right)
    end)

    local reclaimed = 0

    for seen, entity in ipairs(gifts) do
        local actor = ctx:get(entity, component.ACTOR)
        local definition = catalog.get(categories.MONSTERS,
            actor.kind_id)
        local hd = monster_stats.hit_dice(ctx, entity, definition)
        local spared = false

        if reclaimed > 0 then
            spared = ctx:random(streams.CARDS, seen) == 0

            if not spared then
                spared = ctx:random(streams.CARDS, 20) < hd
            end
        end

        if not spared then
            summons.expire(ctx, entity)
            reclaimed = reclaimed + 1
        end
    end

    if reclaimed == 0 then
        return false
    end

    local message

    if reclaimed == 1 and #gifts > 1 then
        message = "Yredelemnul reclaims one of your reaped souls!"
    elseif reclaimed == #gifts then
        message = "Yredelemnul reclaims your reaped souls!"
    else
        message = "Yredelemnul reclaims some of your reaped souls!"
    end

    ctx:emit(channels.RELIGION, message)

    return true
end

return souls
