-- Theory of operation: entrance placement records one 600–800-turn draw
-- in its source-position marker. Population materializes one ECS clock
-- without rerolling or evaluating the legacy DES marker expression.
local component = require("constants.component")
local volcano = require("constants.volcano")
local vaults = require("policy.generation.vaults.catalog")

local portal = {}

-- Only a timed marker from an Volcano entrance belongs to this owner.
function portal.is_marker(record)
    local identity = record and record.identity

    if type(identity) ~= "string" or
        not identity:match("^lua:timed_marker%s*%{") then
        return false
    end

    return vaults.get(record.source_id).family ==
        volcano.ENTRY_FAMILY
end

-- A fixed low/high pair witnesses the one draw made at vault placement.
-- Rejecting a broad range prevents population from drawing it again.
function portal.parse(identity)
    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))

    if not low or not high or low ~= high or
        low < volcano.MIN_DURATION_TURNS or
        low > volcano.MAX_DURATION_TURNS or
        not identity:find("single_timed = true", 1, true) or
        not identity:find('entity = "tunnel"', 1, true) or
        not identity:find('floor = "' ..
            volcano.EXPIRED_MARKER_FLOOR .. '"', 1, true) then
        error("invalid Volcano timed tunnel marker")
    end

    return low
end

-- The clock starts when the chosen entrance is populated. Its origin
-- and deadline are saved before any player can enter it.
function portal.materialize(ctx, level, record)
    local turns = portal.parse(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VOLCANO_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        duration_turns = turns,
        created_aut = ctx:aut(),
        expires_aut = ctx:aut() + turns * 10,
        spent = false,
        closure_reason = volcano.CLOSURE_NONE,
        announced = false,
        next_notice_aut = ctx:aut() + volcano.FIRST_NOTICE_AUT,
        final_warning = false,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- The exact coordinate chooses its gate even if a level contains more
-- than one marker. Travel rechecks this identity during commit.
function portal.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_VOLCANO_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_VOLCANO_PORTAL)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
