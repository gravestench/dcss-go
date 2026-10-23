-- Theory of operation: DES markers are immutable witnesses to cave doors
-- and overflow groups. Population creates one Akara clock per source event;
-- the level grid, rather than a component, owns the changing terrain.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local streams = require("constants.rng_streams")
local volcano = require("constants.volcano")

local hazards = {}

-- Recognize only this domain's marker names. Other Lua and typed markers
-- continue through their existing population owners.
function hazards.is_marker(record)
    local identity = record and record.identity

    return record and record.kind == effects.MARKER and
        type(identity) == "string" and
        (identity == volcano.COLLAPSE_MARKER or
            identity == volcano.OVERFLOW_CLOCK_MARKER or
            identity:sub(1, #volcano.OVERFLOW_CELL_PREFIX) ==
                volcano.OVERFLOW_CELL_PREFIX)
end

-- Consume one inclusive delay draw from a stream kept apart from fog and
-- map generation, so an eruption cannot change later content selection.
local function delay(ctx, minimum, maximum)
    return minimum + ctx:random(streams.VOLCANO_HAZARDS,
        maximum - minimum + 1)
end

-- Read transformed source records in their actual saved order. The first
-- cave marker creates the clock; each sibling still becomes a realized
-- record without creating another independent timer.
local function cave(ctx, level, record)
    local indices = {}
    local xs = {}
    local ys = {}

    for _, candidate in ipairs(level.vault_records or {}) do
        if candidate.source_id == record.source_id and
            candidate.identity == volcano.COLLAPSE_MARKER and
            not candidate.overridden then
            indices[#indices + 1] = candidate.index
            xs[#xs + 1] = candidate.x
            ys[#ys + 1] = candidate.y
        end
    end

    if #indices == 0 then
        error("Volcano cave source has no collapse doorways")
    end

    if indices[1] ~= record.index then
        return
    end

    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VOLCANO_COLLAPSE, {
        level_id = level.id,
        vault_id = record.source_id,
        countdown_aut = delay(ctx, volcano.COLLAPSE_MIN_AUT,
            volcano.COLLAPSE_MAX_AUT),
        record_indices = indices,
        positions_x = xs,
        positions_y = ys,
    })
end

-- The overflow clock belongs to M; A/B/C are indexed slaves with phase
-- labels 2/4/6. Their converted subset is initially empty and will be
-- updated only when a lava mutation actually succeeds.
local function overflow(ctx, level, record)
    local indices = {}
    local groups = {}
    local xs = {}
    local ys = {}

    for _, candidate in ipairs(level.vault_records or {}) do
        local group = (candidate.identity or ""):match("^" ..
            volcano.OVERFLOW_CELL_PREFIX .. "([246])$")

        if candidate.source_id == record.source_id and
            candidate.kind == effects.MARKER and group and
            not candidate.overridden then
            indices[#indices + 1] = candidate.index
            groups[#groups + 1] = tonumber(group)
            xs[#xs + 1] = candidate.x
            ys[#ys + 1] = candidate.y
        end
    end

    if #indices == 0 then
        error("Volcano overflow source has no lava groups")
    end

    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VOLCANO_OVERFLOW, {
        level_id = level.id,
        vault_id = record.source_id,
        clock_index = record.index,
        countdown_aut = delay(ctx, volcano.OVERFLOW_MIN_AUT,
            volcano.OVERFLOW_MAX_AUT),
        phase = 0,
        record_indices = indices,
        groups = groups,
        positions_x = xs,
        positions_y = ys,
        converted_indices = {},
    })
end

-- A realized marker is always returned to the generic population pass.
-- The event-specific owner is created only at its master source position.
function hazards.materialize(ctx, level, record)
    if record.identity == volcano.COLLAPSE_MARKER then
        cave(ctx, level, record)
    elseif record.identity == volcano.OVERFLOW_CLOCK_MARKER then
        overflow(ctx, level, record)
    end

    return {
        level_id = level.id,
        index = record.index,
    }
end

return hazards
