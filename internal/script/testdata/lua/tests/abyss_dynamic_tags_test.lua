-- Source DES can add tags inside a conditional Lua block. The placement
-- path must expose the resolved tags to connector and extra-draw policy;
-- merely recording a TAGS operation would leave those rules inert.
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local minivault = require("policy.generation.vaults.minivault")
local placement = require("policy.generation.vaults.placement")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- A deterministic layout stream lets both placements use the same room.
local function builder()
    local context = {}

    function context:random_u64()
        return 0, 0
    end

    local result = grid.new(context)

    for y = 2, grid.height - 3 do
        for x = 2, grid.width - 3 do
            result:set(x, y, ".")
        end
    end

    return result
end

-- Reuse one parsed map so branch-specific tags cannot leak into its cached
-- catalog definition when the other branch places it later.
function test.run()
    local definition = vaults.get("hangedman_glass_garden")
    local inside = placement.place(nil, builder(), definition, {
        branch_id = branches.BRANCH_ABYSS,
        depth = 3,
        branch_bottom = 7,
    })
    local outside = placement.place(nil, builder(), definition, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 13,
        branch_bottom = 15,
    })

    harness.truthy(inside.tags.no_exits, "Abyss arm suppresses exits")
    harness.falsy(inside.tags.extra, "Abyss arm is not outside decor")
    harness.truthy(outside.tags.extra, "Dungeon arm allows another draw")
    harness.falsy(outside.tags.no_exits, "Dungeon arm keeps entrances")
    harness.falsy(definition.tags.extra, "cached source definition unchanged")
    harness.falsy(minivault.is_extra(definition,
        branches.BRANCH_ABYSS), "Abyss selection ends after decor")
    harness.truthy(minivault.is_extra(definition,
        branches.BRANCH_DUNGEON), "Dungeon selection continues after decor")
end

return test
