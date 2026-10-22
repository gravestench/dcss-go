-- Source DES markers are declarative text. This owner recognizes the two
-- Bazaar constructors and turns them into saved, typed ECS portal state.
local bazaar = require("constants.bazaar")
local component = require("constants.component")
local streams = require("constants.rng_streams")

local portal = {}

-- Only source Bazaar marker constructors belong to this owner. Other
-- legacy marker records remain available to their own domains.
function portal.is_marker(identity)
    return type(identity) == "string" and
        (identity:sub(1, #bazaar.TIMED_MARKER) == bazaar.TIMED_MARKER or
            identity:sub(1, #bazaar.ONE_WAY_MARKER) ==
                bazaar.ONE_WAY_MARKER)
end

-- The DES hook already resolved source depth-dependent bounds. Parse their
-- literal integers without evaluating code from a saved marker string.
function portal.parse(identity)
    if identity:sub(1, #bazaar.ONE_WAY_MARKER) ==
        bazaar.ONE_WAY_MARKER then
        return {
            timed = false,
            low = 0,
            high = 0,
        }
    end

    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))

    if not low or not high or low < 1 or high < low or high > 100000 then
        error("invalid Bazaar timed marker bounds")
    end

    return {
        timed = true,
        low = low,
        high = high,
    }
end

-- Materialization draws the actual duration once. A failed level build
-- rolls this ECS entity and its RNG state back with the staged transaction.
function portal.materialize(ctx, level, record)
    local rule = portal.parse(record.identity)
    local expires_aut = 0

    if rule.timed then
        local turns = rule.low + ctx:random(streams.BAZAAR_PORTAL,
            rule.high - rule.low + 1)

        expires_aut = ctx:aut() + turns * 10
    end

    local entity = ctx:create()

    ctx:add(entity, component.WORLD_BAZAAR_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        low = rule.low,
        high = rule.high,
        expires_aut = expires_aut,
        created_aut = ctx:aut(),
        timed = rule.timed,
        spent = false,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- A player can use only an unspent live arch at the matching map cell.
-- Query order cannot change which saved marker owns that coordinate.
function portal.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_BAZAAR_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_BAZAAR_PORTAL)

        if state.level_id == level_id and state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
