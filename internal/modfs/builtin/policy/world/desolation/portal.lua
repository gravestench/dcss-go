-- Theory of operation: each realized source O marker becomes one saved
-- Akara gate. Its fixed duration is read from the DES hook record, not
-- rerolled by population. The world clock owns closure even while its
-- outside floor is inactive.
local component = require("constants.component")
local vaults = require("policy.generation.vaults.catalog")
local desolation = require("constants.desolation")

local portal = {}

-- A timed marker belongs here only when its source vault came from the
-- Desolation entrance family. Other portals use the same source grammar.
function portal.is_marker(record)
    local identity = record and record.identity

    if type(identity) ~= "string" or
        not identity:match("^lua:timed_marker%s*%{") then
        return false
    end

    return vaults.get(record.source_id).family ==
        desolation.ENTRY_FAMILY
end

-- Require the one drawn duration and the authored expired gateway feature.
-- This catches malformed mods before a false clock enters a save.
function portal.parse(identity)
    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))

    if not low or not high or low ~= high or
        low < desolation.MIN_DURATION_TURNS or
        low > desolation.MAX_DURATION_TURNS or
        not identity:find("single_timed = true", 1, true) or
        not identity:find('floor = "' ..
            desolation.EXPIRED_FEATURE .. '"', 1, true) then
        error("invalid Desolation timed marker")
    end

    return low
end

-- Save source identity and the current absolute action time together.
-- One portal entity is created only after the chosen entrance populates.
function portal.materialize(ctx, level, record)
    local turns = portal.parse(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_DESOLATION_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        duration_turns = turns,
        created_aut = ctx:aut(),
        expires_aut = ctx:aut() + turns * 10,
        spent = false,
        announced = false,
        next_notice_aut = ctx:aut() + desolation.FIRST_NOTICE_AUT,
        final_warning = false,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- Coordinate lookup avoids redirecting a gate merely because a different
-- timed marker happened to be first in the saved component query.
function portal.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_DESOLATION_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_DESOLATION_PORTAL)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
