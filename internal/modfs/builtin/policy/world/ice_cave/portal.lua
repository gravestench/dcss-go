-- Theory of operation: entrance placement records a single fixed timer
-- and hard choice in its source-position marker. Population materializes
-- one ECS gate without drawing a new number or evaluating marker Lua.
local component = require("constants.component")
local ice_cave = require("constants.ice_cave")
local vaults = require("policy.generation.vaults.catalog")

local portal = {}

-- Only a timed marker from an Ice Cave entrance belongs to this owner.
function portal.is_marker(record)
    local identity = record and record.identity

    if type(identity) ~= "string" or
        not identity:match("^lua:timed_marker%s*%{") then
        return false
    end

    return vaults.get(record.source_id).family ==
        ice_cave.ENTRY_FAMILY
end

-- Parse the authored fixed clock and difficulty. A broad range or missing
-- boolean would allow restore to change which cave the entrance opens.
function portal.parse(identity)
    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))
    local hard = identity:match("hard%s*=%s*(%a+)")

    if not low or not high or low ~= high or
        low < ice_cave.MIN_DURATION_TURNS or
        low > ice_cave.MAX_DURATION_TURNS or
        (hard ~= "true" and hard ~= "false") or
        not identity:find("single_timed = true", 1, true) or
        not identity:find('floor = "' ..
            ice_cave.EXPIRED_MARKER_FLOOR .. '"', 1, true) then
        error("invalid Ice Cave timed marker")
    end

    return low, hard == "true"
end

-- The clock starts when the chosen entrance is populated. Its origin
-- difficulty and deadline are saved before any player can enter it.
function portal.materialize(ctx, level, record)
    local turns, hard = portal.parse(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_ICE_CAVE_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        hard = hard,
        duration_turns = turns,
        created_aut = ctx:aut(),
        expires_aut = ctx:aut() + turns * 10,
        spent = false,
        closure_reason = ice_cave.CLOSURE_NONE,
        announced = false,
        next_notice_aut = ctx:aut() + ice_cave.FIRST_NOTICE_AUT,
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
    for _, entity in ipairs(ctx:query({ component.WORLD_ICE_CAVE_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_ICE_CAVE_PORTAL)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
