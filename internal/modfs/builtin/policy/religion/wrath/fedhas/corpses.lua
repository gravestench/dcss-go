-- Fedhas turns a visible corpse into a hostile spore at that corpse's
-- exact cell, then consumes the body. Spore movement and its eventual
-- explosion remain with the ordinary saved monster-spore ECS owner.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local items = require("ids.items")
local monster_flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local range = require("constants.spell_range")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local corpses = {}

-- One body per visible, empty stack can feed this punishment. Sort cell
-- coordinates and entity IDs so unrelated ECS creation order cannot alter
-- which body is used when two corpses share one pile.
local function visible_bodies(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local found = {}
    local occupied = {}

    for _, entity in ipairs(ctx:query({
        component.CORPSE,
        component.ITEM,
        component.POSITION,
    })) do
        local item = ctx:get(entity, component.ITEM)
        local position = ctx:get(entity, component.POSITION)
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if item.kind_id == items.CORPSE_BODY and
            position.level_id == origin.level_id and
            distance <= range.LOS_RADIUS and
            not ctx:actor_at(origin.level_id,
                position.x, position.y) and
            ctx:visible_no_trans(origin.level_id,
                origin.x, origin.y, range.LOS_RADIUS,
                position.x, position.y) then
            found[#found + 1] = {
                entity = entity,
                position = position,
            }
        end
    end

    table.sort(found, function(left, right)
        if left.position.y ~= right.position.y then
            return left.position.y < right.position.y
        end

        if left.position.x ~= right.position.x then
            return left.position.x < right.position.x
        end

        return ctx:id(left.entity) < ctx:id(right.entity)
    end)

    local selected = {}

    for _, body in ipairs(found) do
        local key = body.position.x .. ":" .. body.position.y

        if not occupied[key] then
            selected[#selected + 1] = body
            occupied[key] = true
        end
    end

    return selected
end

-- Source turn_corpse_into_skeleton retains the corpse entity when its
-- monster can leave bones. Keep the vault origin's item ID in sync too.
local function consume(ctx, body)
    local corpse = ctx:get(body, component.CORPSE)
    local definition = catalog.get(categories.MONSTERS,
        corpse.monster_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.NO_SKELETON then
            ctx:destroy(body)
            return
        end
    end

    local item = ctx:get(body, component.ITEM)

    item.kind_id = items.CORPSE_SKELETON
    ctx:set(body, component.ITEM, item)
    corpse.freshness = 110
    corpse.appearance = ctx:random(streams.CORPSE, 255) + 1
    ctx:set(body, component.CORPSE, corpse)

    local origin = ctx:get(body, component.VAULT_ORIGIN)

    if origin then
        origin.kind_id = items.CORPSE_SKELETON
        ctx:set(body, component.VAULT_ORIGIN, origin)
    end
end

-- A visible body counts as a successful punishment even if its precise
-- cell refuses a spore. This matches source fallback to nature spells only
-- when there were no eligible bodies at all.
function corpses.apply(ctx, player)
    local bodies = visible_bodies(ctx, player)

    for _, body in ipairs(bodies) do
        local position = body.position
        local spore = summons.spawn(ctx, player, gods.FEDHAS,
            monsters.MONS_BALLISTOMYCETE_SPORE, 0, nil, {
                attitude = attitudes.HOSTILE,
                source_category = categories.GODS,
                silent_failure = true,
                silent_hostility = true,
                exact = {
                    x = position.x,
                    y = position.y,
                },
            })

        if spore then
            ctx:add(spore, component.MONSTER_SPORE, {
                target = player,
                exploded = false,
            })
        end

        consume(ctx, body.entity)
    end

    return #bodies > 0
end

return corpses
