-- The early-Dungeon forest combines one controller with forty source shapes.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")
local weights = require("policy.generation.vaults.weight")

local test = {}

-- The controller owns only the group size. Its source chance is parsed
-- from DES separately, so no map-ID dispatcher controls forest selection.
local function controller_contract()
    local vault = catalog.get(ids.serial_forest)
    local requested
    local api = {}

    function api:roll(bound)
        return bound - 1
    end

    function api:place_maps(tag, count)
        requested = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_forest", api)

    harness.equal(#vault.rows, 0, "forest controller has no MAP cells")
    harness.equal(requested.tag, tags.SERIAL_FOREST,
        "source forest child tag")
    harness.equal(requested.count, 10,
        "source forest maximum group size")
end

-- D:1 and D:2 multiply each child's base weight; Lair uses its separate
-- source weight. These two shapes have different Lair adjustments.
local function representative_weights()
    local straight = catalog.get(ids.infiniplex_forest_straight_2)
    local corner = catalog.get(ids.infiniplex_forest_corner_1)
    local dungeon = branches.BRANCH_DUNGEON
    local lair = branches.BRANCH_LAIR

    harness.equal(weights.for_branch(straight, dungeon, 1, 15), 9,
        "straight D:1 weight")
    harness.equal(weights.for_branch(straight, dungeon, 2, 15), 6,
        "straight D:2 weight")
    harness.equal(weights.for_branch(straight, dungeon, 3, 15), 3,
        "straight D:3 weight")
    harness.equal(weights.for_branch(straight, lair, 1, 5), 3,
        "straight Lair weight")
    harness.equal(weights.for_branch(corner, dungeon, 1, 15), 6,
        "corner D:1 weight")
    harness.equal(weights.for_branch(corner, lair, 1, 5), 6,
        "corner Lair weight")
end

-- Shared setup changes tree density in Lair while keeping authored masks,
-- vegetation, and the final terrain glyph substitutions in one Lua module.
local function branch_setup()
    local vault = catalog.get(ids.infiniplex_forest_straight_1)

    for _, branch_id in ipairs({
        branches.BRANCH_DUNGEON,
        branches.BRANCH_LAIR,
    }) do
        local emitted = {}
        local api = {}

        function api:branch_id()
            return branch_id
        end

        function api:emit(kind, argument)
            emitted[#emitted + 1] = {
                kind = kind,
                argument = argument,
            }
        end

        hooks.run(vault, "forest_setup.configure", api)

        local tree_choice

        for _, operation in ipairs(emitted) do
            if operation.kind == directives.SUBST and
                operation.argument:match("^E = ") then
                tree_choice = operation.argument
            end
        end

        harness.equal(tree_choice,
            branch_id == branches.BRANCH_LAIR and
                "E = tt12222_" or "E = tt1_",
            "branch-specific forest tree density")
    end
end

-- Every authored MAP must fit and keep both the serial tag and explicit
-- D:1-4/Lair depth rule so it can appear as part of a serial or individually.
local function every_shape_places()
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.tags[tags.SERIAL_FOREST] then
            count = count + 1
            harness.truthy(#definition.depths > 0,
                "forest child has an individual depth rule " .. id)

            local vault = catalog.get(id)
            local builder = grid.new({})

            function builder:roll()
                return 0
            end

            local placed = placement.place(nil, builder, vault, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 2,
                absolute_depth = 2,
                branch_bottom = 15,
                layout_family = "open",
            })

            harness.truthy(placed, "forest piece places " .. id)
            harness.truthy(#vault.rows > 0, "forest piece has MAP rows " .. id)
        end
    end

    harness.equal(count, 40, "complete source forest piece count")
end

-- Verify the whole family, including the weight changes that tag-only
-- placement tests cannot catch.
function test.run()
    controller_contract()
    representative_weights()
    branch_setup()
    every_shape_places()
end

return test
