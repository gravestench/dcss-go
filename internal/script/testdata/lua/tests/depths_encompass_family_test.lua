-- Every Depths whole-floor map and helper must come from the effective
-- layered DES catalog. Source file order cannot decide weighted draws.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local families = require("constants.vault_families")
local features = require("constants.vault_features")
local generated = require("policy.generation.generated")
local harness = require("tests.harness")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local stairs = require("policy.generation.layouts.stairs")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

local expected = {
    box_level_dp = true,
    crystal_crosses_arms_four = true,
    crystal_crosses_arms_one = true,
    crystal_crosses_arms_two = true,
    grunt_profane_halls = true,
    grunt_profane_loot = true,
    grunt_profane_temple_base = true,
    grunt_profane_temple_coc = true,
    grunt_profane_temple_dis = true,
    grunt_profane_temple_geh = true,
    grunt_profane_temple_tar = true,
    grunt_zot_portal = true,
    hangedman_crystal_crosses_colossus = true,
    hangedman_pleasuredromes = true,
    lemuel_river_lethe = true,
    radiant_caverns_a_rkd = true,
    radiant_caverns_b_rkd = true,
}

-- Each source map gets a reproducible independent layout stream. Running
-- the real placement path catches unsupported directives and nested helper
-- faults that catalog registration alone cannot expose.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- A tiny authored stair island must not steal the live arrival from a
-- larger stairless chamber. The whole-map postpass preserves that original
-- exit but supplies missing branch landings in the playable main chamber.
local function disconnected_stair_keeps_main_entry()
    local builder = grid.new(random_context(47))

    builder:set(5, 5, "{")

    for y = 20, 24 do
        for x = 20, 24 do
            builder:set(x, y, ".")
        end
    end

    local paired = stairs.complete_encompass(builder, {
        up = 1,
        down = 1,
    })

    harness.truthy(paired[1].up.x >= 20 and paired[1].up.x <= 24,
        "main chamber owns the generated arrival")
    harness.truthy(paired[1].down.x >= 20 and paired[1].down.x <= 24,
        "main chamber owns the paired departure")
    harness.equal(builder:cell(5, 5), "{",
        "isolated authored exit remains intact")
end

-- The source portal marker sits between Crystal Crosses' calculated SUBST
-- and ambient roster script. Expanding its named hook must preserve that
-- exact directive so any T cell retains its portal metadata after placement.
local function crystal_crosses_keeps_portal_marker()
    local api = {}

    function api:absolute_depth()
        return 23
    end

    function api:branch_id()
        return branches.BRANCH_DEPTHS
    end

    function api:depth()
        return 2
    end

    function api:record()
    end

    local definition = vaults.get("hangedman_crystal_crosses_colossus")
    local operations = hooks.expand(definition, api)

    for _, operation in ipairs(operations) do
        if operation.kind == directives.MARKER and
            operation.argument == "T = lua:props_marker { portal=1 }" then
            return
        end
    end

    error("Crystal Crosses lost its source portal marker")
end

-- Source's `default-depth` is made explicit when definitions are split.
-- All 17 names must be present, but only the seven encompass maps are
-- eligible as a whole-floor primary rather than as tagged child maps.
function test.run()
    vaults.load()
    disconnected_stair_keeps_main_entry()
    crystal_crosses_keeps_portal_marker()

    local count = 0
    local primaries = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == families.DEPTHS_ENCOMPASS then
            harness.truthy(expected[id], "unexpected Depths encompass " .. id)

            count = count + 1

            if definition.tags[tags.UNIQ_DEPTHS_ENCOMPASS] then
                primaries = primaries + 1
                harness.equal(definition.orientation, "encompass",
                    id .. " owns a whole floor")
            end
        end
    end

    harness.equal(count, 17, "complete source Depths encompass file")
    harness.equal(primaries, 7, "seven authored whole-floor maps")

    local encompass = require("policy.generation.vaults.encompass")
    local middle = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 23,
        family = families.DEPTHS_ENCOMPASS,
    }
    local bottom = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 25,
        family = families.DEPTHS_ENCOMPASS,
    }

    local middle_choices = encompass.candidates(middle)
    local bottom_choices = encompass.candidates(bottom)
    local middle_weight = 0
    local bottom_weight = 0

    for _, candidate in ipairs(middle_choices) do
        middle_weight = middle_weight + candidate.weight
    end

    for _, candidate in ipairs(bottom_choices) do
        bottom_weight = bottom_weight + candidate.weight
    end

    harness.equal(#middle_choices, 5,
        "five source Depths:2–3 whole-floor maps")
    harness.equal(middle_weight, 40,
        "source ordinary weights include both rare Radiant maps")
    harness.equal(#bottom_choices, 2,
        "two source Depths:4 explicit end maps")
    harness.equal(bottom_weight, 2,
        "source bottom weights are one each")

    middle.prior_vault_ids = { "lemuel_river_lethe" }

    harness.equal(#encompass.candidates(middle), 0,
        "shared encompass tag is used only once per run")

    -- Exercise every committed MAP directly, including helpers that a
    -- particular seed did not choose through its parent's SUBVAULT slots.
    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.DEPTHS_ENCOMPASS then
            local final = #definition.places > 0
            local depth = final and 4 or 2
            local context = random_context(depth * 101 + #id)
            local builder = grid.new(context)
            local player = {
                branch_id = branches.BRANCH_DEPTHS,
                depth = depth,
                branch_bottom = 4,
                absolute_depth = 21 + depth,
                branch_entries = {
                    [branches.BRANCH_ZOT] = final,
                },
            }
            local okay, placed = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(placed))
            harness.equal(placed.id, id, id .. " keeps source identity")

            if definition.tags[tags.UNIQ_DEPTHS_ENCOMPASS] then
                local built, layout = pcall(encompass.execute, random_context(
                    depth * 101 + #id), definition, {
                    branch_id = branches.BRANCH_DEPTHS,
                    depth = depth,
                    branch_bottom = 4,
                    absolute_depth = 21 + depth,
                    branch_entries = player.branch_entries,
                }, {
                    up = 3,
                    down = final and 0 or 3,
                })

                harness.truthy(built,
                    id .. " full-floor stair completion: " .. tostring(layout))
                harness.equal(layout.primary_id, id,
                    id .. " owns the generated floor")
                harness.truthy(#layout.stairs > 0,
                    id .. " retains reachable source stairs")
            end

            if final then
                local gates = 0
                local keyed

                for _, record in ipairs(placed.records) do
                    if record.kind == effects.FEATURE and
                        record.identity == features.ENTER_ZOT then
                        gates = gates + 1
                        keyed = record
                    end
                end

                harness.equal(gates, 1,
                    id .. " has one scheduled keyed Zot gate")

                local chosen = generated.primary_branch_entry({
                    primary_placement = placed,
                }, branches.BRANCH_ZOT)

                harness.equal(chosen.x, keyed.x,
                    id .. " uses keyed Zot gate before provisional placement")
                harness.equal(chosen.y, keyed.y,
                    id .. " keeps the gate's authored row")

                local links = {
                    {
                        x = 1,
                        y = 1,
                        target_branch_id = branches.BRANCH_ZOT,
                    },
                }
                local protected = { ["1:1"] = true }

                builder:set(1, 1, ">")

                generated.bind_authored_branch_links(builder, links,
                    { placed }, protected)

                harness.equal(builder:cell(1, 1), ".",
                    id .. " removes its provisional Zot stair")
                harness.truthy(links[1].x ~= 1 or links[1].y ~= 1,
                    id .. " binds Zot to its authored feature")
            end
        end
    end
end

return test
