-- Theory of operation: Doroklohe's A marker owns one three-stage
-- countdown. The other source markers identify exactly which walls
-- drop in phase three. Immutable record indices witness the group,
-- while Akara persists the next firing time and completed phase.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local source_group = require("policy.world.wizlab.events.source_group")
local streams = require("constants.rng_streams")
local wizlab = require("constants.wizlab")

local handler = {
    id = "doroklohe",
}

-- The wall property and A clock are distinct source markers in this
-- room; no other Wizard Lab can claim them merely by sharing syntax.
function handler.is_marker(record)
    if record.source_id ~= wizlab.DOROK_MAP_ID or
        record.kind ~= effects.MARKER then
        return false
    end

    return record.identity == wizlab.DOROK_BOX_MARKER or
        (type(record.identity) == "string" and
            record.identity:find(wizlab.DOROK_WALL_PROPERTY,
                1, true) ~= nil)
end

-- Each firing uses the source's inclusive 500–1000-turn delay on a
-- saved stream separate from vault layout and item generation.
local function next_time(ctx)
    local turns = wizlab.DOROK_DELAY_MIN_TURNS +
        ctx:random(streams.WIZLAB_EVENTS,
            wizlab.DOROK_DELAY_RANGE_TURNS)

    return ctx:aut() + turns * 10
end

-- Wall markers are witnesses. Only the unique A clock creates an ECS
-- owner, collecting transformed coordinates from the entire level.
function handler.materialize(ctx, level, record)
    if record.identity == wizlab.DOROK_BOX_MARKER then
        source_group.require_unique_clock(level, record,
            "Doroklohe")

        local indices = {}
        local xs = {}
        local ys = {}

        for _, candidate in ipairs(level.vault_records or {}) do
            if candidate.source_id == record.source_id and
                candidate.kind == effects.MARKER and
                type(candidate.identity) == "string" and
                candidate.identity:find(wizlab.DOROK_WALL_PROPERTY,
                    1, true) then
                indices[#indices + 1] = candidate.index
                xs[#xs + 1] = candidate.x
                ys[#ys + 1] = candidate.y
            end
        end

        if #indices == 0 then
            error("Doroklohe has no falling wall markers")
        end

        local entity = ctx:create()

        ctx:add(entity, component.WORLD_WIZLAB_DOROKLOHE, {
            level_id = level.id,
            vault_id = record.source_id,
            clock_index = record.index,
            phase = 1,
            next_aut = next_time(ctx),
            wall_indices = indices,
            wall_x = xs,
            wall_y = ys,
        })
    end

    return {
        level_id = level.id,
        index = record.index,
    }
end

return handler
