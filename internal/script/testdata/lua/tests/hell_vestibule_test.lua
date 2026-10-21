-- The pinned hell.des gives the Vestibule one encompassing map, five
-- independently selected wings, and authored Hell gates. Exercise the
-- production catalogs and placement path so the source files cannot drift
-- into a parsed-but-unused collection.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local terrain = require("constants.terrain")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local catalog = require("policy.generation.layouts.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local chance = require("policy.generation.vaults.chance")
local selection = require("policy.generation.vaults.selection")
local resolve = require("policy.generation.vaults.specs.resolve")
local vaults = require("policy.generation.vaults.catalog")
local monster_requests = require("constants.vault_monster_requests")
local monster_budget = require("policy.generation.monster_budget")
local hell_size = require("policy.generation.hell.size")
local streams = require("constants.rng_streams")
local vestibule = require("policy.generation.hell.vestibule")

local test = {}
local context_for

-- The ordinary chance stage already discovers source Hell entrances by
-- tag. Depths rolls one member of the family, while a Dungeon floor does
-- not admit a map whose DES depth says Depths only.
local function check_hell_entry_chance()
    vaults.load()

    local depths = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 1,
        branch_bottom = 5,
        absolute_depth = 16,
        layout_family = "rooms",
    }
    local selected = chance.select(grid.new(context_for(5171)), depths)
    local hell_count = 0

    for _, definition in ipairs(selected) do
        if definition.tags.chance_enter_hell then
            hell_count = hell_count + 1
        end
    end

    harness.equal(hell_count, 1,
        "Depths chance stage selects one source Hell entrance")

    local fallback = selection.choose_tag(grid.new(context_for(5172)),
        "fallback_enter_hell", depths)

    harness.equal(fallback.id, "hell_entry",
        "source one-cell gate is available after a failed fit")

    local dungeon = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 15,
        branch_bottom = 15,
        absolute_depth = 15,
        layout_family = "rooms",
    }
    selected = chance.select(grid.new(context_for(5173)), dungeon)

    for _, definition in ipairs(selected) do
        harness.truthy(not definition.tags.chance_enter_hell,
            "Depths-only Hell entrance must not appear in Dungeon")
    end
end

local wing_tags = {
    vestibule_dis = true,
    vestibule_tar = true,
    vestibule_coc = true,
    vestibule_geh = true,
    vestibule_geryon = true,
}

local hell_features = {
    enter_hell = terrain.DNGN_ENTER_HELL,
    exit_hell = terrain.DNGN_EXIT_HELL,
    enter_dis = terrain.DNGN_ENTER_DIS,
    exit_dis = terrain.DNGN_EXIT_DIS,
    enter_gehenna = terrain.DNGN_ENTER_GEHENNA,
    exit_gehenna = terrain.DNGN_EXIT_GEHENNA,
    enter_cocytus = terrain.DNGN_ENTER_COCYTUS,
    exit_cocytus = terrain.DNGN_EXIT_COCYTUS,
    enter_tartarus = terrain.DNGN_ENTER_TARTARUS,
    exit_tartarus = terrain.DNGN_EXIT_TARTARUS,
}

-- A source KFEAT must project its destination into typed terrain so travel
-- can act on the cell without searching a pending vault record.
local function check_hell_feature_projection()
    local projected = 0

    for name, expected in pairs(hell_features) do
        projected = projected + 1
        local cells = {
            { terrain.DNGN_FLOOR },
        }
        local records = {
            {
                kind = effects.FEATURE,
                identity = name,
                x = 0,
                y = 0,
                pending = true,
            },
        }
        local pending = features.apply_vault_terrain(cells, records)

        harness.equal(cells[1][1], expected,
            name .. " projects to its source portal ID")
        harness.equal(#pending, 0,
            name .. " no longer needs a pending record")
    end

    harness.equal(projected, 10, "all source Hell portal kinds project")
end

-- Use the production grid RNG contract with a repeatable seed. The test
-- inspects placed wings rather than reimplementing source tag selection.
context_for = function(seed)
    local state = seed
    local context = {}

    -- Advance two words per bounded draw like the production grid service.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "Vestibule layout stream")
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    -- Zero rolls give the source three-die population budget its minimum.
    function context:random(stream, bound)
        harness.equal(stream, streams.POPULATION_COUNT,
            "Vestibule population budget stream")
        harness.truthy(bound > 0, "population die has positive sides")

        return 0
    end

    return context
end

-- Parsing alone misses malformed substitutions and nested feature
-- resolution. Place each source map through the real operation engine,
-- with a fresh grid so one map cannot mask another map's blocked cells.
local function place_corpus(family, branch_id)
    local paths = mod.paths("vaults/" .. family, ".des")

    for index, path in ipairs(paths) do
        local id = path:match("/([^/]+)%.des$")
        local definition = vaults.get(id)
        local builder = grid.new(context_for(1901 + index))

        -- The one-cell source fallback replaces existing floor; give every
        -- candidate the same legal parent-floor cell instead of a rock-only
        -- builder that production would never offer to that map.
        builder:set(40, 35, ".")

        local player = {
            branch_id = branch_id,
            depth = 1,
            branch_bottom = branch_id == branches.BRANCH_VESTIBULE and
                1 or 5,
            absolute_depth = 27,
        }
        local okay, result = pcall(placement.place, nil, builder,
            definition, player)

        harness.truthy(okay, path .. " placement: " .. tostring(result))
        harness.equal(result.id, id, id .. " placed identity")
    end
end

-- A bare Vestibule simulacrum uses the shared late-game zombie roster.
-- The first bounded draw selects the roster's anaconda, which cannot be
-- obtained from the Vestibule's ordinary ambient spawn list.
local function check_undead_roster()
    local context = {}

    function context:random(_, bound)
        harness.truthy(bound > 0, "zombie roster has a positive total")

        return 0
    end

    local selected = {
        name = monster_requests.RANDOM_SIMULACRUM,
        source = "Vestibule simulacrum",
    }
    local site = {
        branch_id = branches.BRANCH_VESTIBULE,
        local_depth = 1,
    }
    local result = resolve.monster(context, selected, 27, site)

    harness.equal(result.base_id, monsters.MONS_ANACONDA,
        "Vestibule corpse species comes from late zombie roster")
end

-- The actual level policy must turn the authored map's source upward exits
-- into live Hell return arches and retain all four branch entrances.
local function check_generated_vestibule()
    local output = vestibule.generate(context_for(2191), {
        prior_vault_ids = {},
    })
    local level = output.level
    local counts = {}

    for _, row in ipairs(level.cells) do
        for _, feature in ipairs(row) do
            counts[feature] = (counts[feature] or 0) + 1
        end
    end


    harness.equal(level.branch_id, branches.BRANCH_VESTIBULE,
        "authored Vestibule branch")
    harness.equal(level.vault_id, "vestibule_of_hell_subvaulted",
        "authored encompassing map")
    harness.equal(level.initial_monsters, 3,
        "Vestibule starts with source three-die monster budget")
    harness.truthy((counts[terrain.DNGN_EXIT_HELL] or 0) > 0,
        "source up exits become Hell return arches")
    harness.truthy((counts[terrain.DNGN_ENTER_DIS] or 0) > 0,
        "Dis entrance survives feature projection")
    harness.truthy((counts[terrain.DNGN_ENTER_GEHENNA] or 0) > 0,
        "Gehenna entrance survives feature projection")
    harness.truthy((counts[terrain.DNGN_ENTER_COCYTUS] or 0) > 0,
        "Cocytus entrance survives feature projection")
    harness.truthy((counts[terrain.DNGN_ENTER_TARTARUS] or 0) > 0,
        "Tartarus entrance survives feature projection")
    harness.equal(level.cells[level.entry_y + 1][level.entry_x + 1],
        terrain.DNGN_EXIT_HELL, "arrival uses a live return arch")
end

-- The four Hell branches use three six-sided monster dice, not the
-- twelve-sided default used by the Vestibule and most ordinary branches.
local function check_hell_monster_budget()
    local hell_branches = {
        branches.BRANCH_DIS,
        branches.BRANCH_GEHENNA,
        branches.BRANCH_COCYTUS,
        branches.BRANCH_TARTARUS,
    }

    for _, branch_id in ipairs(hell_branches) do
        local draws = 0
        local context = {}

        function context:random(stream, bound)
            harness.equal(stream, streams.POPULATION_COUNT,
                "Hell monster budget uses the population stream")
            harness.equal(bound, 6,
                "Hell monster budget has six-sided source dice")
            draws = draws + 1

            return bound - 1
        end

        harness.equal(monster_budget.roll(context, branch_id, 1), 18,
            "Hell monster budget uses all three source dice")
        harness.equal(draws, 3, "Hell monster budget makes three draws")
    end
end

-- Every currently ported Hell layout must build inside the source compact
-- extent without changing another level's builder dimensions. Exercising
-- each actual hook catches static 80x70 assumptions below the catalog.
local function check_compact_hell_layouts()
    local candidates = {
        {
            branch_id = branches.BRANCH_DIS,
            ids = {
                "layout_gridville",
                "layout_jigsaw",
                "layout_regular_city",
                "layout_overlapping_boxes",
                "layout_subdivisions",
            },
        },

        {
            branch_id = branches.BRANCH_GEHENNA,
            ids = {
                "layout_gehenna_lava_caves",
                "layout_gehenna_pools_basic",
                "layout_gehenna_pools_box",
                "layout_gehenna_pools_triple",
            },
        },

        {
            branch_id = branches.BRANCH_COCYTUS,
            ids = {
                "layout_cocytus_water_paths",
                "layout_ice_bergs",
            },
        },

        {
            branch_id = branches.BRANCH_TARTARUS,
            ids = {
                "layout_grid_maze",
                "layout_honeycomb",
            },
        },
    }

    for _, family in ipairs(candidates) do
        local branch = register.get("branches", family.branch_id)
        local width, height = hell_size.for_branch(branch, 1)

        harness.equal(width, 40, "ordinary Hell builder width")
        harness.equal(height, 35, "ordinary Hell builder height")

        for index, id in ipairs(family.ids) do
            local definition = catalog.get(id)
            local context = context_for(3100 + index)
            local result = catalog.execute(context, definition,
                family.branch_id, 1, {
                    up = 1,
                    down = 1,
                })

            harness.equal(#result.rows, height, id .. " compact row count")
            harness.equal(#result.rows[1], width,
                id .. " compact column count")
            harness.truthy(#result.stairs >= 1,
                id .. " has a connected Hell exit pair")
        end
    end
end

-- The source map family is complete before generation chooses a wing.
-- Each chosen wing must contribute its actual authored map to the result.
function test.run()
    check_hell_entry_chance()
    check_generated_vestibule()
    check_hell_monster_budget()
    check_compact_hell_layouts()
    check_hell_feature_projection()
    check_undead_roster()
    harness.equal(#mod.paths("vaults/hell_entry", ".des"), 23,
        "pinned Hell entrance count")
    harness.equal(#mod.paths("vaults/vestibule", ".des"), 36,
        "pinned Vestibule wing count")

    place_corpus("hell_entry", branches.BRANCH_DEPTHS)
    place_corpus("vestibule", branches.BRANCH_VESTIBULE)

    local definition = catalog.get("vestibule_of_hell_subvaulted")
    local result = catalog.execute(context_for(2187), definition,
        branches.BRANCH_VESTIBULE, 1, {
            up = 0,
            down = 0,
        })
    local selected = {}

    for _, id in ipairs(result.vault_ids or {}) do
        local map = vaults.get(id)

        for tag in pairs(wing_tags) do
            if map.tags[tag] then
                selected[tag] = (selected[tag] or 0) + 1
            end
        end
    end

    for tag in pairs(wing_tags) do
        harness.equal(selected[tag], 1, tag .. " appears once")
    end

    harness.equal(result.id, definition.id, "Vestibule layout identity")
    harness.equal(#result.rows, 70, "full-sized Vestibule layout")
end

return test
