-- Assign the saved god partition to placed Temple altars. Some source maps
-- advertise a different count than their raw B glyphs produce; DCSS turns
-- excess placeholders into floor when its altar list runs out. We also fill
-- a shortfall on safe authored floor so every saved god has an altar.
local effects = require("constants.vault_effects")
local glyphs = require("constants.vault_glyphs")

local altars = {}

-- KFEAT _ = B is another source spelling for a random altar. Convert it
-- to the same record kind before assigning a god so inspection is uniform.
local function is_placeholder(record)
    return record.kind == effects.SOURCE_FEATURE and
        record.identity == glyphs.terrain.B or
        record.kind == effects.FEATURE and record.identity == "B"
end

-- Coordinate order is stable even when DES operation order or keyed
-- record placement changes, and it matches the grid's row scan.
local function before(left, right)
    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- Copy hook arguments before adding the god ID. This prevents several
-- altar records from sharing a mutable table after save projection.
local function assign_god(record, god_id)
    local arguments = {}

    for key, value in pairs(record.arguments or {}) do
        arguments[key] = value
    end

    arguments.god_id = god_id
    record.arguments = arguments
    record.kind = effects.SOURCE_FEATURE
    record.identity = glyphs.terrain.B
    record.pending = false
end

-- Other authored objects and stairs reserve their cells. Floor colours
-- and tiles are visual records, so they do not block a missing altar.
local function reserved_cells(placed)
    local reserved = {}

    for _, exit in ipairs(placed.exits) do
        reserved[exit.x .. ":" .. exit.y] = true
    end

    for _, record in ipairs(placed.records) do
        if record.kind ~= effects.COLOUR and
            record.kind ~= effects.TILE and
            record.kind ~= effects.GENERATION_RULE then
            reserved[record.x .. ":" .. record.y] = true
        end
    end

    return reserved
end

-- Choose a free cell already owned by this map, nearest to an authored
-- altar. Row/column ties make legacy shortfall repair seed-independent.
local function shortfall_cell(builder, placed, existing, reserved)
    local candidates = {}

    for _, point in ipairs(placed.occupied) do
        local key = point.x .. ":" .. point.y

        if builder:cell(point.x, point.y) == "." and
            not reserved[key] then
            local distance = math.huge

            for _, altar in ipairs(existing) do
                distance = math.min(distance,
                    math.abs(point.x - altar.x) +
                    math.abs(point.y - altar.y))
            end

            candidates[#candidates + 1] = {
                x = point.x,
                y = point.y,
                distance = distance,
            }
        end
    end

    table.sort(candidates, function(left, right)
        if left.distance ~= right.distance then
            return left.distance < right.distance
        end

        return before(left, right)
    end)

    local chosen = candidates[1]

    if not chosen then
        error("Temple map " .. placed.id ..
            " has no safe floor for its missing altar")
    end

    reserved[chosen.x .. ":" .. chosen.y] = true

    return chosen
end

-- Replace raw random placeholders with exactly the saved ordered gods.
-- Source MAP rows remain untouched; only placed level data is reconciled.
function altars.assign(builder, placed, chosen)
    if placed.id ~= chosen.map_id or
        #chosen.main_god_ids ~= chosen.altar_count then
        error("Temple altar assignment disagrees with its saved plan")
    end

    local placeholders = {}
    local retained = {}
    local used = {}

    for _, record in ipairs(placed.records) do
        if is_placeholder(record) then
            local key = record.x .. ":" .. record.y

            if not used[key] then
                placeholders[#placeholders + 1] = record
                used[key] = true
            end
        else
            retained[#retained + 1] = record
        end
    end

    table.sort(placeholders, before)

    for index, record in ipairs(placeholders) do
        if index > chosen.altar_count then
            builder:set(record.x, record.y, ".")
        else
            assign_god(record, chosen.main_god_ids[index])
            retained[#retained + 1] = record
        end
    end

    local reserved = reserved_cells(placed)

    for index = #placeholders + 1, chosen.altar_count do
        local point = shortfall_cell(builder, placed,
            placeholders, reserved)
        local record = {
            kind = effects.SOURCE_FEATURE,
            identity = glyphs.terrain.B,
            source = ".",
            x = point.x,
            y = point.y,
            vault_id = placed.id,
            arguments = {
                generated_for_count = true,
            },
        }

        assign_god(record, chosen.main_god_ids[index])
        retained[#retained + 1] = record
        placeholders[#placeholders + 1] = record
    end

    placed.records = retained

    return placed
end

return altars
