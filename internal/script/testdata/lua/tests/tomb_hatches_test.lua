-- The production Tomb marker methods and graph resolver define the same
-- route contract that placed DES files use, including optional hatches.
local markers = require("policy.generation.tomb.hatch_markers")
local hatches = require("policy.generation.tomb.hatches")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- Capture one production marker declaration at a final map coordinate.
local function marker(method, x, y)
    local record
    local api = {}

    function api:record(kind, arguments)
        record = {
            kind = kind,
            arguments = arguments,
            x = x,
            y = y,
        }
    end

    markers[method](api)

    return record
end

-- A named destination can exist when its optional source was removed by
-- a source NSUBST. Multiple remaining exits still share one landing.
function test.run()
    local first = {
        id = 1,
        local_depth = 1,
        cells = {
            { terrain.DNGN_FLOOR, terrain.DNGN_FLOOR, terrain.DNGN_FLOOR },
            { terrain.DNGN_FLOOR, terrain.DNGN_STONE_STAIRS_DOWN_I,
                terrain.DNGN_STONE_STAIRS_DOWN_I },
        },
        stairs = {},
        vault_records = {
            marker("name_tomb2_entry", 1, 1),
            marker("name_tomb2_entry", 2, 1),
            marker("dest_tomb1_hall_entry", 0, 0),
        },
    }
    local second = {
        id = 2,
        local_depth = 2,
        cells = {
            { terrain.DNGN_FLOOR, terrain.DNGN_FLOOR },
            { terrain.DNGN_FLOOR, terrain.DNGN_FLOOR },
        },
        stairs = {},
        vault_records = {
            marker("dest_tomb2_entry", 1, 1),
        },
    }

    harness.equal(hatches.resolve({ first, second }), 2,
        "two outgoing hatches share one landing")
    harness.equal(#first.stairs, 2)
    harness.equal(#second.stairs, 0,
        "landing does not gain a reciprocal stair")

    first.stairs = {}
    second.local_depth = 1

    harness.equal(pcall(hatches.resolve, { first, second }), false,
        "a hatch cannot land on the same depth")

    second.local_depth = 2
    first.cells[2][2] = terrain.DNGN_STONE_STAIRS_UP_I

    harness.equal(pcall(hatches.resolve, { first, second }), false,
        "an up hatch cannot land on the deeper floor")

    first.cells[2][2] = terrain.DNGN_STONE_STAIRS_DOWN_I
    second.vault_records[#second.vault_records + 1] =
        marker("dest_tomb2_entry", 0, 0)

    local accepted = pcall(hatches.resolve, { first, second })

    harness.equal(accepted, false,
        "duplicate destination name must fail")
end

return test
