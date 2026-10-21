-- These tests use committed DES definitions, so marker spelling and glyph
-- placement come from the same files as production generation.
local catalog = require("policy.generation.vaults.catalog")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transport_ids = require("constants.transporter")
local transporters = require("policy.generation.transporters")
local vaults = require("ids.vaults")

local test = {}

-- Give the resolver a level-sized mutable terrain grid without copying the
-- feature schema or writing a second map parser in this test.
local function floor_cells()
    local cells = {}

    for y = 1, 70 do
        local row = {}

        for x = 1, 80 do
            row[x] = terrain.DNGN_FLOOR
        end

        cells[y] = row
    end

    return cells
end

-- Place each real source map, then move its markers as a group to model
-- separate same-floor vaults without depending on a random layout origin.
local function markers_from(ctx, id, shift_x)
    local placed = placement.place(ctx, grid.new(ctx), catalog.get(id))
    local records = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MARKER then
            record.x = record.x + shift_x
            records[#records + 1] = record
        end
    end

    return records
end

-- Find a source or destination by its authored DES marker prefix.
local function named(records, prefix, name)
    for _, record in ipairs(records) do
        if record.identity == prefix .. '("' .. name .. '")' then
            return record
        end
    end
end

-- A source marker and its named landing become painted, durable link data.
local function tutorial_links(ctx)
    local records = markers_from(ctx,
        vaults.spicycebolla_arrival_transporter_tutorial, 0)
    local level = {
        cells = floor_cells(),
        vault_records = records,
    }

    transporters.resolve(level)

    local source = named(records, transport_ids.SOURCE_CALL,
        "tut_entry")
    local destination = named(records, transport_ids.DESTINATION_CALL,
        "tut_entry")

    harness.truthy(source, "tutorial source marker missing")
    harness.truthy(destination, "tutorial destination marker missing")
    harness.equal(level.cells[source.y + 1][source.x + 1],
        terrain.DNGN_TRANSPORTER, "source feature")
    harness.equal(level.cells[destination.y + 1][destination.x + 1],
        terrain.DNGN_TRANSPORTER_LANDING, "landing feature")
    harness.equal(source.arguments[transport_ids.DESTINATION_X],
        tostring(destination.x), "saved destination x")
    harness.equal(source.arguments[transport_ids.DESTINATION_Y],
        tostring(destination.y), "saved destination y")
    harness.falsy(source.pending, "resolved source remains pending")
end

-- The three subway maps can point at destinations in other placed vaults.
local function subway_links(ctx)
    local records = {}
    local ids = {
        vaults.nicolae_sub_station_stone,
        vaults.nicolae_sub_station_crystal,
        vaults.nicolae_sub_station_metal,
    }

    for index, id in ipairs(ids) do
        for _, marker in ipairs(markers_from(ctx, id, index * 10)) do
            records[#records + 1] = marker
        end
    end

    local level = {
        cells = floor_cells(),
        vault_records = records,
    }

    transporters.resolve(level)

    local source = named(records, transport_ids.SOURCE_CALL,
        "nico_crystal_station")
    local destination = named(records, transport_ids.DESTINATION_CALL,
        "nico_crystal_station")

    harness.truthy(source, "subway source marker missing")
    harness.truthy(destination, "subway destination marker missing")
    harness.equal(source.arguments[transport_ids.DESTINATION_X],
        tostring(destination.x), "cross-vault link x")
    harness.equal(source.arguments[transport_ids.DESTINATION_Y],
        tostring(destination.y), "cross-vault link y")
end

-- Authored maps cannot leave an orphan endpoint or silently choose among
-- duplicate destinations; an overwritten pair has no surviving transport.
local function invalid_markers(ctx)
    -- Each malformed case starts from an independent real source map so
    -- earlier corruption cannot make a later rejection pass by accident.
    local function tutorial()
        return {
            cells = floor_cells(),
            vault_records = markers_from(ctx,
                vaults.spicycebolla_arrival_risky_transporter, 0),
        }
    end

    local missing = tutorial()
    local destination = named(missing.vault_records,
        transport_ids.DESTINATION_CALL, "tut_risky")

    for index, marker in ipairs(missing.vault_records) do
        if marker == destination then
            table.remove(missing.vault_records, index)
            break
        end
    end

    harness.falsy(pcall(transporters.resolve, missing),
        "source without destination passed")

    local unused = tutorial()
    local source = named(unused.vault_records,
        transport_ids.SOURCE_CALL, "tut_risky")

    for index, marker in ipairs(unused.vault_records) do
        if marker == source then
            table.remove(unused.vault_records, index)
            break
        end
    end

    harness.falsy(pcall(transporters.resolve, unused),
        "unused destination passed")

    local duplicate = tutorial()
    local second = {}
    local first = named(duplicate.vault_records,
        transport_ids.DESTINATION_CALL, "tut_risky")

    for key, value in pairs(first) do
        second[key] = value
    end

    second.x = second.x + 1
    duplicate.vault_records[#duplicate.vault_records + 1] = second

    harness.falsy(pcall(transporters.resolve, duplicate),
        "duplicate destination passed")

    local erased = tutorial()

    for _, marker in ipairs(erased.vault_records) do
        marker.overridden = true
    end

    transporters.resolve(erased)

    harness.falsy(named(erased.vault_records, transport_ids.SOURCE_CALL,
        "tut_risky").arguments, "overridden marker gained a link")
end

-- Keep a single entry point for the production-VM test runner.
function test.run(ctx)
    tutorial_links(ctx)
    subway_links(ctx)
    invalid_markers(ctx)
end

return test
