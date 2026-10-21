-- Transporter links are authored, immutable same-floor topology. Restore
-- compares saved marker arguments to their named destinations and grid cells.
local effects = require("constants.vault_effects")
local generator = require("policy.generation.transporters")
local ids = require("constants.transporter")
local component = require("constants.component")
local terrain = require("constants.terrain")

local transporters = {}

-- Keep every source marker but allow several sources to share a single
-- named landing, exactly as the DES postprocessor does at generation time.
local function indexed_markers(level)
    local sources = {}
    local destinations = {}

    for _, record in ipairs(level.vault_records or {}) do
        if record.kind == effects.MARKER and not record.overridden then
            local kind, name = generator.parse(record.identity or "")
            local arguments = record.arguments or {}

            if kind == ids.SOURCE_CALL then
                sources[name] = sources[name] or {}
                sources[name][#sources[name] + 1] = record
            elseif kind == ids.DESTINATION_CALL then
                if destinations[name] then
                    error("duplicate saved transporter destination " .. name)
                end

                destinations[name] = record
            elseif arguments[ids.DESTINATION_X] or
                arguments[ids.DESTINATION_Y] then
                error("nontransporter marker has a destination link")
            end
        end
    end

    return sources, destinations
end

-- Match the saved link coordinates and feature to the destination marker.
local function validate_source(ctx, level_id, name, source, destination)
    local arguments = source.arguments or {}

    if source.pending or destination.pending or
        tostring(destination.x) ~= arguments[ids.DESTINATION_X] or
        tostring(destination.y) ~= arguments[ids.DESTINATION_Y] or
        source.x == destination.x and source.y == destination.y or
        ctx:cell(level_id, source.x, source.y) ~=
            terrain.DNGN_TRANSPORTER or
        ctx:cell(level_id, destination.x, destination.y) ~=
            terrain.DNGN_TRANSPORTER_LANDING then
        error("invalid saved transporter link " .. name)
    end
end

-- A painted outbound feature must have a checked marker; a forged terrain
-- cell cannot masquerade as a source whose marker was removed from the save.
local function validate_grid(ctx, level_id, sources, landings)
    local width, height = ctx:level_size(level_id)

    if not width or not height then
        error("transporter validation has no level grid " .. level_id)
    end

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local feature = ctx:cell(level_id, x, y)
            local location = x .. ":" .. y

            if feature == terrain.DNGN_TRANSPORTER and
                not sources[location] then
                error("unmarked saved transporter at " .. x .. ":" .. y)
            end

            if feature == terrain.DNGN_TRANSPORTER_LANDING and
                not landings[location] then
                error("unmarked saved transporter landing at " .. location)
            end
        end
    end
end

-- Learned destinations cannot be invented or redirected independently of
-- the level's immutable links, even though the player component is editable.
local function validate_knowledge(ctx, links)
    local player = ctx:player()
    local knowledge = player and ctx:get(player,
        component.TRANSPORTER_KNOWLEDGE)

    if not knowledge then
        return
    end

    for key, destination in pairs(knowledge.links) do
        if links[key] ~= destination then
            error("invalid saved transporter knowledge " .. key)
        end
    end
end

-- Validate all levels together so player knowledge can point to any floor
-- already generated before this save, not merely the active level.
function transporters.validate(ctx, input)
    local links = {}

    for _, level in ipairs(input.levels or {}) do
        local sources, destinations = indexed_markers(level)
        local marked_sources = {}
        local marked_landings = {}

        for name, records in pairs(sources) do
            local destination = destinations[name]

            if not destination then
                error("saved transporter " .. name .. " has no landing")
            end

            for _, source in ipairs(records) do
                validate_source(ctx, level.id, name, source, destination)

                local location = source.x .. ":" .. source.y
                local key = level.id .. ":" .. location

                marked_sources[location] = true
                links[key] = destination.x .. ":" .. destination.y
            end

            marked_landings[destination.x .. ":" .. destination.y] = true
        end

        for name in pairs(destinations) do
            if not sources[name] then
                error("unused saved transporter landing " .. name)
            end
        end

        validate_grid(ctx, level.id, marked_sources, marked_landings)
    end

    validate_knowledge(ctx, links)

    return {}
end

register.policy({
    id = "save.validate_transporters",
    run = transporters.validate,
})

return transporters
