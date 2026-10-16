local component = require("constants.component")
local status = require("constants.unique_item_status")
local purpose_ids = require("constants.item_generation_purpose")
local catalog = require("policy.catalog")

local history = {}

function history.initialise(ctx, player)
    if not ctx:has(player, component.PLAYER_UNIQUE_HISTORY) then
        ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
            status = {},
        })
    end
end

function history.status(ctx, player, id)
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history was not initialised")
    end

    return state.status[id]
end

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

function history.release(ctx, player, id)
    local state = ctx:get(player, component.PLAYER_UNIQUE_HISTORY)

    if not state then
        error("player unique history was not initialised")
    end

    state.status[id] = nil
    ctx:set(player, component.PLAYER_UNIQUE_HISTORY, state)
end

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
