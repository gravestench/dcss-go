-- The ruined city serial owns one controller and fifty-six source pieces.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local controller = require("policy.generation.vaults.controller")
local connect = require("policy.generation.vaults.connect")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")

local test = {}

-- A zero layout stream chooses the source's rare all-pillar mode. It still
-- requests a portal only in Depths, where that source branch can roll one.
local function controller_pillar_mode()
    local vault = catalog.get(ids.serial_column_ruins)
    local requests = {}
    local api = { context = { branch_id = branches.BRANCH_DEPTHS } }

    function api:roll()
        return 0
    end

    function api:one_in()
        return true
    end

    function api:place_maps(tag, count)
        requests[#requests + 1] = { tag = tag, count = count }
    end

    function api:level_tiles(floor, wall)
        harness.equal(floor, "floor_rough_brown",
            "rare floor tile")
        harness.equal(wall, "wall_catacombs",
            "rare rock tile")
    end

    hooks.run(vault, "place_column_ruins", api)

    harness.equal(#vault.rows, 0, "controller has no MAP cells")
    harness.equal(requests[1].tag, tags.COLUMN_RUINS_PILLAR,
        "rare source pillar tag")
    harness.equal(requests[1].count, 10,
        "minimum source pillar count")
    harness.equal(requests[2].tag, tags.COLUMN_RUINS_PORTAL,
        "Depths portal tag")
    harness.equal(requests[2].count, 1,
        "Depths portal request")
end

-- The ordinary controller mode requests portal, fancy, and simple pools
-- in that order, preserving zero-count calls without selecting a map.
local function controller_ordinary_mode()
    local vault = catalog.get(ids.serial_column_ruins)
    local requests = {}
    local api = { context = { branch_id = branches.BRANCH_DUNGEON } }

    function api:roll()
        return 1
    end

    function api:one_in()
        return false
    end

    function api:place_maps(tag, count)
        requests[#requests + 1] = { tag = tag, count = count }
    end

    hooks.run(vault, "place_column_ruins", api)

    harness.equal(requests[1].tag, tags.COLUMN_RUINS_PORTAL,
        "ordinary portal request first")
    harness.equal(requests[1].count, 0,
        "Dungeon has no source portal request")
    harness.equal(requests[2].tag, tags.COLUMN_RUINS_FANCY,
        "fancy source request second")
    harness.equal(requests[2].count, 1,
        "source fancy count")
    harness.equal(requests[3].tag, tags.COLUMN_RUINS_SIMPLE,
        "simple source request last")
    harness.equal(requests[3].count, 5,
        "source simple count")
end

-- A whole-level tile choice is saved as one typed record owned by the
-- controller, rather than disappearing after the post-place callback.
local function level_tiles_become_level_data()
    local placed = {}
    local api = controller.new(grid.new({}), {}, placed, nil,
        ids.serial_column_ruins)

    api:level_tiles("floor_rough_brown", "wall_catacombs")

    harness.equal(#placed, 1, "one level tile record map")
    harness.equal(placed[1].id, ids.serial_column_ruins,
        "controller owns the level tile request")
    harness.equal(placed[1].records[1].kind, effects.GENERATION_RULE,
        "level tile request has a typed kind")
    harness.equal(placed[1].records[1].arguments.rock_tile,
        "wall_catacombs", "source rock tile survives")
end

-- Every child must load, keep its tag-only eligibility, and project the
-- original geometry through the common substitutions and portal hooks.
local function every_piece_places()
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if id:match("^column_ruins_") then
            count = count + 1
            local definition = register.get(categories.VAULTS, id)
            local vault = catalog.get(id)
            local builder = grid.new({})

            function builder:roll()
                return 0
            end

            harness.equal(#definition.depths, 0,
                "children are controller-only " .. id)
            harness.truthy(#vault.rows > 0, "source MAP exists " .. id)

            local placed = placement.place(nil, builder, vault, {
                branch_id = branches.BRANCH_DEPTHS,
                depth = 1,
                absolute_depth = 22,
                branch_bottom = 4,
            })

            harness.truthy(placed, "source piece places " .. id)

            if definition.tags.no_exits then
                local source_cell = builder:cell(placed.entry.x,
                    placed.entry.y)

                harness.equal(#placed.exits, 0,
                    "solid pillar has no invented exit")
                connect.finish(nil, builder, placed)
                harness.equal(builder:cell(placed.entry.x,
                    placed.entry.y), source_cell,
                    "solid decoration gains no corridor")
            end
        end
    end

    harness.equal(count, 56, "complete source ruined-city child count")
end

-- The family test covers the all-pillar controller and each child map;
-- separate layout selection tests cover the generic CHANCE stage.
function test.run()
    controller_pillar_mode()
    controller_ordinary_mode()
    level_tiles_become_level_data()
    every_piece_places()
end

return test
