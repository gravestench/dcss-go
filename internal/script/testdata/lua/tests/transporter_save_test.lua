-- A saved transporter must still point to its authored marker destination
-- and to the matching painted features after the level grid is restored.
local catalog = require("policy.generation.vaults.catalog")
local component = require("constants.component")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local save = require("policy.save.transporters")
local terrain = require("constants.terrain")
local transport_ids = require("constants.transporter")
local transporters = require("policy.generation.transporters")
local vaults = require("ids.vaults")

local test = {}

-- Use a committed DES map and the production terrain pass for the save
-- fixture, so tests do not redeclare marker names or link fields.
local function source_level(ctx)
    local builder = grid.new(ctx)
    local map = catalog.get(vaults.spicycebolla_arrival_risky_transporter)
    local placed = placement.place(ctx, builder, map)
    local cells = features.decode_source_rows(builder:rows())
    local level = {
        id = 1,
        cells = cells,
        vault_records = features.apply_vault_terrain(cells,
            placed.records, ctx, 1),
    }

    transporters.resolve(level)

    local source
    local destination

    for _, record in ipairs(level.vault_records) do
        if record.identity == transport_ids.SOURCE_CALL ..
            '("tut_risky")' then
            source = record
        elseif record.identity == transport_ids.DESTINATION_CALL ..
            '("tut_risky")' then
            destination = record
        end
    end

    return level, source, destination
end

-- Read restored cells from the generated level while forwarding the real
-- ECS player and component methods through the production test world.
local function save_context(ctx, level, player)
    local game = setmetatable({}, { __index = ctx })

    -- Read the generated cells as the restored grid would expose them.
    function game:cell(_, x, y)
        return level.cells[y + 1] and level.cells[y + 1][x + 1]
    end

    -- The player component holds the learned links checked by this policy.
    function game:player()
        return player
    end

    -- Grid size bounds the scan for forged source and landing terrain.
    function game:level_size()
        return #level.cells[1], #level.cells
    end

    return game
end

-- Corrupt one field at a time, checking that validation accepts the source
-- state first and rejects each impossible restored state afterward.
function test.run(ctx)
    local level, source, destination = source_level(ctx)
    local player = ctx:create()
    local game = save_context(ctx, level, player)
    local input = {
        levels = { level },
    }

    save.validate(game, input)

    local original_x = source.arguments[transport_ids.DESTINATION_X]

    source.arguments[transport_ids.DESTINATION_X] =
        tostring(destination.x + 1)
    harness.falsy(pcall(save.validate, game, input),
        "forged destination coordinate passed")
    source.arguments[transport_ids.DESTINATION_X] = original_x

    level.cells[source.y + 1][source.x + 1] = terrain.DNGN_FLOOR
    harness.falsy(pcall(save.validate, game, input),
        "missing transporter terrain passed")
    level.cells[source.y + 1][source.x + 1] = terrain.DNGN_TRANSPORTER

    level.cells[destination.y + 1][destination.x + 1] =
        terrain.DNGN_FLOOR
    harness.falsy(pcall(save.validate, game, input),
        "missing landing terrain passed")
    level.cells[destination.y + 1][destination.x + 1] =
        terrain.DNGN_TRANSPORTER_LANDING

    local stray_x = source.x + 1
    local original_stray = level.cells[source.y + 1][stray_x + 1]

    level.cells[source.y + 1][stray_x + 1] =
        terrain.DNGN_TRANSPORTER_LANDING
    harness.falsy(pcall(save.validate, game, input),
        "unmarked landing terrain passed")
    level.cells[source.y + 1][stray_x + 1] = original_stray

    local duplicate = {}

    for key, value in pairs(destination) do
        duplicate[key] = value
    end

    duplicate.x = duplicate.x + 1
    level.vault_records[#level.vault_records + 1] = duplicate
    harness.falsy(pcall(save.validate, game, input),
        "duplicate landing name passed")
    table.remove(level.vault_records)

    local source_key = table.concat({ 1, source.x, source.y }, ":")

    ctx:add(player, component.TRANSPORTER_KNOWLEDGE, {
        links = {
            [source_key] = destination.x .. ":" .. destination.y,
        },
    })
    save.validate(game, input)

    ctx:set(player, component.TRANSPORTER_KNOWLEDGE, {
        links = {
            [source_key] = "1:1",
        },
    })
    harness.falsy(pcall(save.validate, game, input),
        "forged learned destination passed")
end

return test
