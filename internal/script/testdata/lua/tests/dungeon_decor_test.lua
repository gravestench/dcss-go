-- The source deep-Dungeon decoration controller requests one child from
-- every effective map carrying the decor tag, including mod-added maps.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local tags = require("constants.vault_tags")

local test = {}

-- The source controller has no cells and only enters the chance stage
-- from D:14 onward or in Depths; its child draw follows placement.
local function controller_contract()
    local vault = catalog.get(ids.dungeon_decor)
    local request
    local api = {}

    -- A fake child selector records the source's one-map request.
    function api:place_maps(tag, count)
        request = {
            tag = tag,
            count = count,
        }
    end

    hooks.run(vault, "place_decor", api)

    harness.equal(#vault.rows, 0, "decor controller has no MAP cells")
    harness.equal(request.tag, tags.DECOR, "decor child selector tag")
    harness.equal(request.count, 1, "source decor child count")
    harness.falsy(eligibility.depth(vault, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 13,
        branch_bottom = 15,
    }), "decor excluded before D:14")
    harness.truthy(eligibility.depth(vault, {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 14,
        branch_bottom = 15,
    }), "decor eligible from D:14")
    harness.equal(depth.chance(vault,
        branches.BRANCH_DUNGEON, 14), 8000,
        "source eighty percent chance")
    harness.truthy(eligibility.depth(vault, {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 1,
        branch_bottom = 5,
    }), "decor registered for Depths")
end

-- The global decor tag is shared by Dungeon, Slime and Swamp. Check the
-- effective Dungeon pool using the same branch eligibility as selection,
-- so importing another branch cannot change this controller's contract.
local function child_catalog_contract()
    local dungeon = 0
    local swamp = 0
    local dungeon_context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 14,
        branch_bottom = 15,
        absolute_depth = 14,
    }
    local swamp_context = {
        branch_id = branches.BRANCH_SWAMP,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local map = catalog.get(id)

        if map.tags[tags.DECOR] then
            if eligibility.tag(map, dungeon_context) then
                harness.falsy(map.family == "swamp",
                    "Swamp decor cannot enter the Dungeon pool")
                dungeon = dungeon + 1
            end

            if map.family == "swamp" and
                eligibility.tag(map, swamp_context) then
                swamp = swamp + 1
            end
        end
    end

    harness.truthy(dungeon > 0, "Dungeon decor has eligible children")
    harness.truthy(swamp > 0, "Swamp decor joins its own branch pool")
end

-- Keep the controller and its tagged child pool in one category check.
function test.run()
    catalog.load()
    controller_contract()
    child_catalog_contract()
end

return test
