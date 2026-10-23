-- Theory of operation: the A marker owns one monk countdown. Seven
-- numbered source markers remain location witnesses for one-shot
-- shadow messages. The death marker shares the same A cell, and
-- suppresses both behaviors when the named statue dies.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local source_group = require("policy.world.wizlab.events.source_group")
local streams = require("constants.rng_streams")
local wizlab = require("constants.wizlab")

local handler = {
    id = "wucad",
}

-- Only this source map can attach Wucad event state, even if another
-- mod uses a similar descriptive marker on a different floor.
function handler.is_marker(record)
    if record.source_id ~= wizlab.WUCAD_MAP_ID or
        record.kind ~= effects.MARKER or
        type(record.identity) ~= "string" then
        return false
    end

    return record.identity:sub(1, #wizlab.WUCAD_MESSAGE_MARKER) ==
        wizlab.WUCAD_MESSAGE_MARKER or
        record.identity == wizlab.WUCAD_MONKS_MARKER or
        record.identity == wizlab.WUCAD_DEATH_MARKER
end

-- A source timer draw is made when the level populates. Subsequent
-- intervals are redrawn only when its callback actually fires.
local function next_time(ctx)
    local turns = wizlab.WUCAD_MONK_DELAY_MIN_TURNS +
        ctx:random(streams.WIZLAB_EVENTS,
            wizlab.WUCAD_MONK_DELAY_RANGE_TURNS)

    return ctx:aut() + turns * 10
end

-- Collect transformed marker positions in spot order, independent of
-- record iteration or filesystem order. Reject a missing or duplicate
-- source spot before creating the Akara state.
local function message_group(level, vault_id)
    local found = {}
    local death

    for _, record in ipairs(level.vault_records or {}) do
        if record.source_id == vault_id and
            record.kind == effects.MARKER and
            type(record.identity) == "string" then
            local spot = record.identity:match("^" ..
                wizlab.WUCAD_MESSAGE_MARKER ..
                "%s*%{%s*spot%s*=%s*(%d+)%s*%}$")

            if spot then
                spot = tonumber(spot)

                if spot < 1 or spot > 7 then
                    error("Wucad has unknown message spot")
                end

                found[spot] = found[spot] or {}
                found[spot][#found[spot] + 1] = record
            elseif record.identity == wizlab.WUCAD_DEATH_MARKER then
                if death then
                    error("Wucad has duplicate statue death markers")
                end

                death = record
            end
        end
    end

    local indices = {}
    local spots = {}
    local xs = {}
    local ys = {}
    local done = {}

    for spot = 1, 7 do
        local record = found[spot]

        if not record then
            error("Wucad lacks message spot " .. spot)
        end

        for _, cell in ipairs(record) do
            indices[#indices + 1] = cell.index
            spots[#spots + 1] = spot
            xs[#xs + 1] = cell.x
            ys[#ys + 1] = cell.y
        end

        done[spot] = false
    end

    if not death then
        error("Wucad lacks its statue death marker")
    end

    return indices, spots, xs, ys, done, death.index
end

-- Only the monk marker creates state. Message and death markers remain
-- realized witnesses that the save validator can join later.
function handler.materialize(ctx, level, record)
    if record.identity == wizlab.WUCAD_MONKS_MARKER then
        source_group.require_unique_clock(level, record, "Wucad")

        local indices, spots, xs, ys, done, death_index =
            message_group(level, record.source_id)
        local entity = ctx:create()

        ctx:add(entity, component.WORLD_WIZLAB_WUCAD, {
            level_id = level.id,
            vault_id = record.source_id,
            monks_index = record.index,
            death_index = death_index,
            next_aut = next_time(ctx),
            suppressed = false,
            message_indices = indices,
            message_spot = spots,
            message_x = xs,
            message_y = ys,
            message_done = done,
        })
    end

    return {
        level_id = level.id,
        index = record.index,
    }
end

return handler
