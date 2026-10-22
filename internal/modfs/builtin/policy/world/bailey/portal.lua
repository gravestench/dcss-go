-- Theory of operation: a Bailey entry's source-position hook records one
-- fixed 600–800-turn timed marker. Population turns that marker into one
-- ECS clock; it never rerolls the duration or evaluates marker text.
local component = require("constants.component")
local bailey = require("constants.bailey")
local vaults = require("policy.generation.vaults.catalog")

local portal = {}

-- Marker syntax is shared by several portal branches. Source family and
-- the constructor must both match before this owner claims the record.
function portal.is_marker(record)
    local identity = record and record.identity

    if type(identity) ~= "string" or
        not identity:match("^lua:timed_marker%s*%{") then
        return false
    end

    return vaults.get(record.source_id).family == bailey.ENTRY_FAMILY
end

-- Source hooks draw one theme and one duration. Both are literal marker
-- fields and become persistent state without a new RNG draw on entry.
function portal.parse(identity)
    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))
    local theme = identity:match('bailey_type%s*=%s*"([%w_]+)"')

    if not low or not high or low ~= high or
        (theme ~= bailey.AXE and theme ~= bailey.POLEARM) or
        low < bailey.MIN_DURATION_TURNS or
        low > bailey.MAX_DURATION_TURNS or
        not identity:find("single_timed = true", 1, true) or
        not identity:find('floor = "' ..
            bailey.EXPIRED_MARKER_FLOOR .. '"', 1, true) then
        error("invalid Bailey timed marker")
    end

    return low, theme
end

-- Source chance selection and placement have already finished. The
-- clock begins when the chosen entrance is actually populated.
function portal.materialize(ctx, level, record)
    local turns, theme = portal.parse(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_BAILEY_PORTAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        theme = theme,
        duration_turns = turns,
        created_aut = ctx:aut(),
        expires_aut = ctx:aut() + turns * 10,
        spent = false,
        closure_reason = bailey.CLOSURE_NONE,
        announced = false,
        next_notice_aut = ctx:aut() + bailey.FIRST_NOTICE_AUT,
        final_warning = false,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- The coordinate must identify the same clock before travel spends it.
-- No order-dependent first matching record can redirect another gate.
function portal.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_BAILEY_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_BAILEY_PORTAL)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
