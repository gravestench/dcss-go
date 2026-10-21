-- Resolve source DES transporter markers only after every map on this level
-- has been placed. A station may land in a different source vault.
local effects = require("constants.vault_effects")
local terrain = require("constants.terrain")
local ids = require("constants.transporter")

local transporters = {}

-- Parse only the two source marker calls; other marker kinds stay with their
-- own gameplay policies. Quoted names are level-local link identities.
local function marker_name(identity, prefix)
    if not identity:find(prefix, 1, true) then
        return nil
    end

    local name = identity:match("^" .. prefix ..
        "%(%s*\"([%w_]+)\"%s*%)$")

    if not name then
        error("invalid transporter marker " .. identity)
    end

    return name
end

-- Expose one parser to generation and restore checks so a mod's marker
-- spelling cannot be accepted by one phase and ignored by the other.
function transporters.parse(identity)
    local source = marker_name(identity, ids.SOURCE_CALL)

    if source then
        return ids.SOURCE_CALL, source
    end

    local destination = marker_name(identity, ids.DESTINATION_CALL)

    if destination then
        return ids.DESTINATION_CALL, destination
    end
end

-- Reject marker coordinates before painting terrain or saving a link.
local function checked_cell(level, record)
    local row = level.cells[record.y + 1]

    if not row or not row[record.x + 1] then
        error("transporter marker is outside the level grid")
    end
end

-- Record source and destination names without depending on DES file order.
local function collect(level)
    local sources = {}
    local destinations = {}

    for _, record in ipairs(level.vault_records or {}) do
        if record.kind == effects.MARKER and not record.overridden then
            local identity = record.identity or ""
            local kind, name = transporters.parse(identity)
            local source_name = kind == ids.SOURCE_CALL and name
            local destination_name = kind == ids.DESTINATION_CALL and name

            if source_name or destination_name then
                checked_cell(level, record)
            end

            if source_name then
                sources[source_name] = sources[source_name] or {}
                sources[source_name][#sources[source_name] + 1] = record
            elseif destination_name then
                if destinations[destination_name] then
                    error("duplicate transporter destination " ..
                        destination_name)
                end

                destinations[destination_name] = record
            end
        end
    end

    return sources, destinations
end

-- Sort names so a malformed mod always reports the same first error.
local function names(records)
    local sorted = {}

    for name in pairs(records) do
        sorted[#sorted + 1] = name
    end

    table.sort(sorted)

    return sorted
end

-- Pair source and destination records, paint the exact DCSS feature IDs,
-- and retain typed link coordinates for save and runtime lookup.
function transporters.resolve(level)
    local sources, destinations = collect(level)

    for _, name in ipairs(names(sources)) do
        local destination = destinations[name]

        if not destination then
            error("transporter " .. name .. " has no destination")
        end

        for _, source in ipairs(sources[name]) do
            if source.x == destination.x and
                source.y == destination.y then
                error("transporter " .. name .. " lands on its source")
            end

            source.arguments = source.arguments or {}
            source.arguments[ids.DESTINATION_X] = tostring(destination.x)
            source.arguments[ids.DESTINATION_Y] = tostring(destination.y)
            source.pending = false
            level.cells[source.y + 1][source.x + 1] =
                terrain.DNGN_TRANSPORTER
        end

        destination.pending = false
        level.cells[destination.y + 1][destination.x + 1] =
            terrain.DNGN_TRANSPORTER_LANDING
    end

    for _, name in ipairs(names(destinations)) do
        if not sources[name] then
            error("unused transporter destination " .. name)
        end
    end
end

return transporters
