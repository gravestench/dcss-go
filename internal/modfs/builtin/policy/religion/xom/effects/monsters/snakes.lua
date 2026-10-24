-- Snakes to Sticks transforms each nearby hostile snake into a permanent
-- unbranded missile or weapon. The item generator owns the item fields;
-- the grid owner removes the snake without granting a kill reward.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local events = require("ids.xom_events")
local generation = require("policy.item_generation")
local items = require("ids.items")
local monsters = require("ids.monsters")
local monster_stats = require("policy.combat.monster_stats")
local quality = require("constants.vault_item_quality")
local streams = require("constants.rng_streams")

local effect = {}

-- This source array is a weapon-shape rule, not an item catalog load order.
-- The rarity check below reads each weapon's canonical commonness field.
local stickable = {
    items.WPN_CLUB,
    items.WPN_SPEAR,
    items.WPN_TRIDENT,
    items.WPN_HALBERD,
    items.WPN_GLAIVE,
    items.WPN_QUARTERSTAFF,
    items.WPN_SHORTBOW,
    items.WPN_LONGBOW,
    items.WPN_GIANT_CLUB,
    items.WPN_GIANT_SPIKED_CLUB,
}

-- Source x_chance_in_y avoids an RNG draw for impossible and certain odds.
local function chance(ctx, stream, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(stream, denominator) < numerator
end

-- Higher-HD snakes may become heavier weapons. Bound retries so a modded
-- catalog with impossible commonness cannot hang the player action.
local function weapon_for(ctx, hd, stream)
    for _ = 1, 100 do
        local index = ctx:random(stream, hd)
        local kind_id = stickable[index + 1]

        if kind_id then
            local definition = catalog.get("items", kind_id)
            local rarity = definition.weapon.commonness

            if ctx:random(stream, hd) <= rarity or
                not chance(ctx, stream, index, hd) then
                return kind_id
            end
        end
    end

    return items.WPN_CLUB
end

-- A hostile snake is identified by its source genus, not by an adder-only
-- kind list, so new snake species inherit the event automatically.
function effect.candidates(ctx, player)
    local candidates = {}

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = actor and catalog.get("monsters",
                actor.kind_id)

            if definition and definition.genus_id ==
                monsters.MONS_SNAKE then
                candidates[#candidates + 1] = {
                    entity = monster,
                    definition = definition,
                }
            end
        end
    end

    return candidates
end

-- Dismissal drops any carried gear at the old cell, then clears spatial
-- occupancy before destroying the actor. No death hook or XP is invoked.
local function dismiss(ctx, monster, position)
    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == monster then
            if ctx:has(item, component.EQUIPPED) then
                ctx:remove(item, component.EQUIPPED)
            end

            ctx:remove(item, component.CARRIED_BY)
            ctx:add(item, component.POSITION, {
                level_id = position.level_id,
                x = position.x,
                y = position.y,
            })
        end
    end

    ctx:remove_actor(monster, position.level_id)
    ctx:destroy(monster)
end

-- Materialize the stick before dismissing the snake. If generation fails,
-- the encompassing Lua action rolls back instead of losing the actor.
local function turn_to_stick(ctx, candidate, stream)
    local monster = candidate.entity
    local position = ctx:get(monster, component.POSITION)
    local hd = math.max(1, monster_stats.hit_dice(ctx, monster,
        candidate.definition))
    local missile = ctx:random(stream, 2) == 0
    local kind_id = missile and items.MI_JAVELIN or
        weapon_for(ctx, hd, stream)
    local rolled = generation.roll(ctx, {
        kind_id = kind_id,
        depth = math.max(1, math.floor(hd / 3) - 1),
        quality = quality.ORDINARY,
        quantity = 1,
        allow_uniques = false,
        site = "Xom snakes to sticks",
    })

    rolled.ego = ""

    local item = generation.create(ctx, rolled, {
        position = {
            level_id = position.level_id,
            x = position.x,
            y = position.y,
        },
    })

    dismiss(ctx, monster, position)

    return item
end

-- Apply to every eligible snake in no-trans sight, retaining independent
-- class and weapon draws for each transformed monster.
function effect.apply(ctx, player, event_id, _, request)
    if event_id ~= events.GOOD_SNAKES then
        error("snakes effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local changed = 0

    for _, candidate in ipairs(effect.candidates(ctx, player)) do
        if turn_to_stick(ctx, candidate, stream) then
            changed = changed + 1
        end
    end

    if changed > 0 then
        ctx:emit(channels.RELIGION,
            "Xom turns snakes into sticks!")
    end

    return changed
end

return effect
