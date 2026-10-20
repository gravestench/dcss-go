-- Room layout tests exercise the production source hook, grid, and stair
-- postpass together. They intentionally do not restate the room schema.
local layout = require("policy.generation.layouts.layout_rooms")
local stairs = require("policy.generation.layouts.stairs")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Vary low and high words to exercise the same bounded draw that live
-- generation uses; a simple sequence would choose the same room shape.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "room layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- A source room map must be meaningfully different from the basic trail
-- layout and leave enough connected floor for three ordinary stair pairs.
local function generates_connected_rooms(seed)
    local floor = layout.layout_rooms({
        ctx = random_context(seed),
        branch = "D",
        depth = 9,
    })
    local pair_count = #stairs.complete(floor.builder)
    local floor_count = 0

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            if floor.builder:cell(x, y) == "." then
                floor_count = floor_count + 1
            end
        end
    end

    harness.equal(pair_count, 3, "room layout stair count")
    harness.truthy(#floor.rooms > 1, "multiple source room attempts accepted")
    harness.truthy(floor_count > 30, "room layout carved a playable region")
    harness.equal(#floor.builder:rows(), grid.height, "room layout height")
end

-- The checked-in DES is the authority for this layout's ID and hook name;
-- validate it through the same code that a modded layout will use at boot.
local function source_hook_resolves()
    local path = "vaults/layout/layout_rooms.des"
    local definition = des.parse(path, mod.read(path))

    harness.equal(definition.id, "layout_rooms", "source room layout ID")
    hooks.validate(definition)
end

-- A second seed catches accidental dependence on a single favorable RNG
-- trace while keeping this test focused on one layout family.
function test.run()
    source_hook_resolves()
    generates_connected_rooms(1)
    generates_connected_rooms(47)
end

return test
