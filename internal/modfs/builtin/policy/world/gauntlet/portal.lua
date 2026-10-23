-- Theory of operation: a source timed marker at O becomes one saved
-- Akara gate. The marker's draw determines the deadline; population
-- does not reroll when the floor is entered, revisited, or restored.
local component = require("constants.component")
local gauntlet = require("constants.gauntlet")
local vaults = require("policy.generation.vaults.catalog")

local portal = {}

-- The shared temporary-portal registry asks each domain to recognize
-- only its own source markers. The family path is independent of a mod
-- file's physical layer or enumeration order.
function portal.is_marker(record)
    local identity = record and record.identity

    if type(identity) ~= "string" or
        not identity:match("^lua:timed_marker%s*%{") then
        return false
    end

    local source_id = record.source_id or record.vault_id

    if not source_id then
        return false
    end

    return vaults.get(source_id).family ==
        gauntlet.ENTRY_FAMILY
end

-- The marker must contain one 400–600-turn draw and the source's
-- stone-arch replacement. Reject a bad mod before saving a false clock.
function portal.parse(identity)
    local low = tonumber(identity:match("low%s*=%s*(%d+)"))
    local high = tonumber(identity:match("high%s*=%s*(%d+)"))

    if not low or not high or low ~= high or
        low < gauntlet.MIN_DURATION_TURNS or
        low > gauntlet.MAX_DURATION_TURNS or
        not identity:find("single_timed = true", 1, true) or
        not identity:find('floor = "' ..
            gauntlet.EXPIRED_FEATURE .. '"', 1, true) then
        error("invalid Gauntlet timed marker")
    end

    return low
end

-- Record absolute action time once, when the entrance is realized.
-- World time continues even while this outside floor is inactive.
function portal.materialize(ctx, level, record)
    local turns = portal.parse(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_GAUNTLET_PORTAL, {
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
        next_notice_aut = ctx:aut() + gauntlet.FIRST_NOTICE_AUT,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- Match the actual gate cell. A different timed portal on the same
-- floor must never hijack this Gauntlet travel transaction.
function portal.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_GAUNTLET_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_GAUNTLET_PORTAL)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return entity, state
        end
    end

    return nil, nil
end

return portal
