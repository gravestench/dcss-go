-- Run every committed main Temple map through the production floor builder.
-- This catches differences between a standalone DES fit and a live level.
local catalog = require("policy.generation.temple.catalog")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local floor = require("policy.generation.temple.floor")
local harness = require("tests.harness")
local plan = require("policy.generation.temple.plan")

local test = {}

-- Select one source-advertised size per map. The placement test separately
-- checks every advertised size, so this one covers the live floor boundary.
local function advertised_count(definition)
    for count = 0, 22 do
        if definition.tags["temple_altars_" .. count] then
            return count
        end
    end

    error("Temple map has no advertised altar count: " .. definition.id)
end

-- Use the real Temple builder and terrain decoder, including whole-level
-- border fills. The god list comes from production policy rather than a
-- second test-only pantheon.
function test.run(ctx)
    local gods = plan.god_ids()

    for _, id in ipairs(catalog.main_ids()) do
        local definition = catalog.main(id)
        local count = advertised_count(definition)
        local selected = {
            map_id = id,
            altar_count = count,
            main_god_ids = {},
            overflow_god_ids = {},
        }

        for index, god_id in ipairs(gods) do
            local group = index <= count and
                selected.main_god_ids or selected.overflow_god_ids

            group[#group + 1] = god_id
        end

        local okay, built = pcall(floor.build, ctx, selected, {
            species_id = "SP_HUMAN",
            name = "Temple tester",
            started = true,
        })

        harness.truthy(okay, id .. " live floor failed: " .. tostring(built))
        harness.equal(built.arrival.id, id,
            "live Temple keeps the chosen map")
        harness.truthy(#built.source_up > 0,
            id .. " has no source or generated return stair")

        local assigned = 0
        local border

        for _, record in ipairs(built.records) do
            if record.kind == effects.SOURCE_FEATURE and
                record.identity == "DNGN_RANDOM_ALTAR" then
                assigned = assigned + 1
            elseif record.kind == effects.BORDER_FILL then
                border = record
            end
        end

        harness.equal(assigned, count,
            id .. " has the saved number of live altars")

        local cells = features.decode_source_rows(built.layout.builder:rows())

        features.apply_vault_terrain(cells, built.records, ctx, 1)

        if border then
            local outside = cells[1][1]

            harness.truthy(outside == "DNGN_OPEN_SEA" or
                outside == "DNGN_LAVA_SEA",
                id .. " did not apply its source border terrain")
            harness.falsy(border.pending,
                id .. " border remained a pending terrain effect")
        end
    end
end

return test
