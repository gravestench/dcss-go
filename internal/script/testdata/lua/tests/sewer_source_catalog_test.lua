-- Theory of operation: all source Sewer maps load through the production
-- DES catalog, and each destination is placed as an entire floor before a
-- timed drain can offer it to the player. This test pins authored geometry
-- and validates every named hook independently of a rare entrance roll.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local des = require("policy.generation.vaults.des")
local extra = require("policy.generation.vaults.extra")
local effects = require("constants.vault_effects")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local placement = require("policy.generation.vaults.placement")
local chance = require("policy.generation.vaults.chance")
local eligibility = require("policy.generation.vaults.eligibility")
local sewer = require("policy.generation.sewer.level")
local terrain = require("constants.terrain")

local test = {}

-- Independent bounded draws prevent path enumeration from changing the
-- placement of a particular source map.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Compare source MAP blocks as a set keyed by NAME. The hash includes every
-- row, including leading and trailing spaces that control map placement.
local function source_digest(paths)
    local maps = {}

    for _, path in ipairs(paths) do
        local map = des.parse(path, mod.read(path))

        maps[#maps + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(maps)

    local hash = 0

    for byte in (table.concat(maps, "\n")):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    harness.equal(hash, 853149203, "authored Sewer MAP corpus")
end

-- The source's encompass layouts may use all 80 columns. Their exits must
-- survive KFEAT projection on the full grid, including the wide sea map.
local function place_destination(map)
    local builder = grid.new(random_context())
    local player = {
        branch_id = branches.BRANCH_SEWER,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 4,
    }
    local okay, placed = pcall(placement.place, nil, builder,
        map, player, {
            whole_level = true,
        })

    harness.truthy(okay, map.id .. " placement: " .. tostring(placed))

    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, random_context(), 1)
    local exit_found = false

    for _, row in ipairs(cells) do
        for _, cell in ipairs(row) do
            exit_found = exit_found or
                cell == terrain.DNGN_EXIT_SEWER
        end
    end

    harness.truthy(exit_found, map.id .. " lost its Sewer exit")
    harness.truthy(#records > 0,
        map.id .. " lost all authored content records")

    if map.id == "sewer_sea" then
        local species_names = 0

        for _, record in ipairs(records) do
            if record.kind == effects.MONSTER and
                record.arguments and record.arguments.name_species then
                species_names = species_names + 1
            end
        end

        harness.equal(species_names, 2,
            "Sewer sea's authored siren and avatar species names")
    end
end

-- Every entrance must fit a Dungeon floor and retain its timed marker.
-- Source chance tags are checked before the hook runs, while KFEAT and
-- marker records are checked after the real placement path executes.
local function place_entry(map)
    local builder = grid.new(random_context())

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, ".")
        end
    end

    local player = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        absolute_depth = 4,
    }
    local context = {
        protected = {},
        required = {},
        player = player,
    }
    local placed, reason = extra.place(nil, builder, map, context)

    harness.truthy(placed,
        map.id .. " entrance placement: " .. tostring(reason))

    local gate = false
    local marker = false

    for _, record in ipairs(placed.records) do
        if record.kind == effects.FEATURE and
            record.identity == "enter_sewer" then
            gate = true
        elseif record.kind == effects.MARKER and
            record.identity:find("timed_marker", 1, true) then
            marker = true
        end
    end

    harness.truthy(gate, map.id .. " lost its drain")
    harness.truthy(marker, map.id .. " lost its timer")
end

-- Validate the effective, layered corpus before any live portal selects
-- one map. Entry tags must be static because hooks run after selection.
function test.run()
    local entries = mod.paths("vaults/sewer_entry", ".des")
    local destinations = mod.paths("vaults/sewer", ".des")

    harness.equal(#entries, 15, "source Sewer entrances")
    harness.equal(#destinations, 19, "source Sewer destinations")

    for _, path in ipairs(entries) do
        local map = des.parse(path, mod.read(path))

        harness.truthy(map.tags.chance_sewer and
            map.tags.uniq_sewer and #map.chances > 0,
            map.id .. " lacks source chance selection")
        harness.equal(chance.group_tag(map), "chance_sewer",
            map.id .. " chance family")
        harness.truthy(eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 4,
            branch_bottom = 15,
            absolute_depth = 4,
        }), map.id .. " cannot appear on D:4")

        for depth = 3, 6 do
            harness.truthy(eligibility.depth(map, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = depth,
                branch_bottom = 15,
                absolute_depth = depth,
            }), map.id .. " cannot appear at source depth " .. depth)
        end

        for _, depth in ipairs({ 2, 7 }) do
            harness.truthy(not eligibility.depth(map, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = depth,
                branch_bottom = 15,
                absolute_depth = depth,
            }), map.id .. " leaks beyond source D:3–6 range")
        end

        hooks.validate(map)
        place_entry(map)
    end

    for _, path in ipairs(destinations) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        place_destination(map)
    end

    local all = {}

    for _, path in ipairs(entries) do
        all[#all + 1] = path
    end

    for _, path in ipairs(destinations) do
        all[#all + 1] = path
    end

    source_digest(all)

    local candidates = sewer.candidates({})

    harness.equal(#candidates, 19, "effective Sewer destination pool")

    for index = 2, #candidates do
        harness.truthy(candidates[index - 1].id < candidates[index].id,
            "Sewer candidates follow stable map ID order")
    end

    local generated = sewer.generate(random_context(), {})

    harness.equal(catalog.get(generated.level.vault_id).family,
        "sewer", "generated source Sewer map")
    local arrival_row = generated.level.cells[generated.level.entry_y + 1]

    harness.equal(arrival_row[generated.level.entry_x + 1],
        terrain.DNGN_FLOOR,
        "safe Sewer arrival")
end

return test
