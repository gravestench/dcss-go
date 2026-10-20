local component = require("constants.component")
local status = require("constants.unique_item_status")
local purpose_ids = require("constants.item_generation_purpose")
local catalog = require("policy.catalog")

local history = {}

-- Unique artefact claims live in persistent history so later generation cannot repeat an already placed item.
function history.initialise(ctx, player)
    if not ctx:has(player, component.PLAYER_UNIQUE_HISTORY) then
        ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
            status = {},
            monsters = {},
        })
    end
end

-- Example: history.status(ctx, player, artefact_id) bars an ordinary unique from appearing again.
-- Read the player's persisted unique ledger; missing initialization is corrupt generation state.
function history.status(ctx, player, id)
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history was not initialised")
    end

    return state.status[id]
end

-- Level finds become ordinary claims; gifts and acquirement retain the nonlevel fallback status.
function history.mark(ctx, player, id, purpose)
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history was not initialised")
    end

    local nonlevel = purpose == purpose_ids.ACQUIREMENT or
        purpose == purpose_ids.GOD_GIFT

    state.status[id] = nonlevel and status.NONLEVEL or status.ORDINARY
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, state)
end

-- Clear a failed or abandoned claim so the unique can be selected later.
function history.release(ctx, player, id)
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history was not initialised")
    end

    state.status[id] = nil
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, state)
end

-- Saved unique statuses must name active artefacts and one supported claim state.
function history.validate(state)
    if not state then
        error("player unique history is missing")
    end

    for id, value in pairs(state.status) do
        local okay = pcall(catalog.get, "artefacts", id)

        if not okay then
            error("unknown player unique history " .. id)
        end

        if value ~= status.ORDINARY and value ~= status.NONLEVEL and
            value ~= status.LOST_IN_ABYSS then
            error("invalid player unique history status " .. id)
        end
    end
end

return history
