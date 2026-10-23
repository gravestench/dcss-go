-- The committed DES files are the runtime source of Desolation geometry.
-- Compare every map byte to the pinned source digest without reading the
-- C++ checkout during normal builds. Sorting by ID makes path order inert.
local des = require("policy.generation.vaults.des")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local tags = require("constants.vault_tags")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local level = require("policy.generation.desolation.level")
local placement = require("policy.generation.vaults.placement")
local selection = require("policy.generation.vaults.selection")
local terrain = require("constants.terrain")
local feature_names = require("constants.vault_feature_names")
local vaults = require("policy.generation.vaults.catalog")
local portal = require("policy.world.desolation.portal")
local item_ids = require("ids.items")
local monster_ids = require("ids.monsters")

local test = {}

-- Give every placement test the same small, deterministic draw source.
-- The production builder still owns all selection and placement rules.
local function seeded_context(seed)
    local value = seed
    local context = {}

    -- The builder expects a two-word draw for its internal random stream.
    function context:random_u64()
        value = (value * 48271) % 2147483647

        return 0, value
    end

    -- Hooks use the bounded draw contract rather than selecting fixtures.
    function context:random(_stream, bound)
        self:random_u64()

        return value % bound
    end

    return context
end

-- Source MAP rows remain the most useful drift check: a map can parse
-- successfully even after a reward cell or passage has been removed.
local function digest(maps)
    local parts = {}

    for _, map in ipairs(maps) do
        parts[#parts + 1] = map.id .. ":" ..
            table.concat(map.rows, "\n")
    end

    table.sort(parts)

    local hash = 0

    for byte in table.concat(parts, "\n"):gmatch(".") do
        hash = (hash * 31 + string.byte(byte)) % 4294967296
    end

    return hash
end

-- Parse the same effective files as production, including replacements.
local function maps_in(directory)
    local maps = {}

    for _, path in ipairs(mod.paths(directory, ".des")) do
        local map = des.parse(path, mod.read(path))

        hooks.validate(map)
        maps[#maps + 1] = map
    end

    return maps
end

-- Use the builder's actual random interface to place each complete map.
-- This catches hook, helper, and terrain errors beyond catalog parsing.
local function generate(id)
    local context = seeded_context(17)

    local okay, result = pcall(level.generate, context, {
        layout_id = id,
    })

    harness.truthy(okay, id .. " failed to generate: " .. tostring(result))
    harness.equal(result.level.vault_id, id, id .. " lost its source ID")

    local exits = 0

    for _, row in ipairs(result.level.cells) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_DESOLATION then
                exits = exits + 1
            end
        end
    end

    harness.truthy(exits > 0, id .. " has no return arch")

    local named_idols = 0

    for _, record in ipairs(result.level.vault_records) do
        if record.kind == effects.FEATURE_NAME and
            record.arguments.name ==
                feature_names.DESOLATION_RUINED_IDOL and
            record.arguments.feature_id ==
                terrain.DNGN_GRANITE_STATUE and
            record.arguments.bounds_width > 0 and
            record.arguments.bounds_height > 0 then
            named_idols = named_idols + 1
        end
    end

    harness.truthy(named_idols > 0,
        id .. " lost its inspectable ruined-idol name")

    return result.level
end

-- Every helper needs to work when SUBVAULT chooses it, including rare
-- one-weight treasure rooms that a single seeded floor may never draw.
local function place_ruin(id)
    local context = seeded_context(29)

    local player = {
        branch_id = branches.BRANCH_DESOLATION,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 20,
    }
    local builder = grid.new(context)
    local okay, result = pcall(placement.place, context, builder,
        vaults.get(id), player, {})

    harness.truthy(okay, id .. " failed source placement: " ..
        tostring(result))
    harness.truthy(#result.occupied > 0,
        id .. " did not place terrain")
end

-- All nine source gates must emit one timer at O after their own local
-- substitutions. A parsed map alone cannot prove its scripted arch runs.
local function place_entrance(id)
    local context = seeded_context(31)

    local player = {
        branch_id = branches.BRANCH_ELF,
        depth = 1,
        branch_bottom = 3,
        absolute_depth = 20,
    }
    local builder = grid.new(context)
    local okay, result = pcall(placement.place, context, builder,
        vaults.get(id), player, {})

    harness.truthy(okay, id .. " failed source placement: " ..
        tostring(result))

    local timers = 0
    local slug_bodies = 0
    local slug_triggers = 0

    for _, record in ipairs(result.records) do
        if record.kind == effects.MARKER and
            record.vault_id == id and
            record.identity:match("^lua:timed_marker%s*%{") then
            local duration = portal.parse(record.identity)

            harness.truthy(duration >= 600 and duration <= 800,
                id .. " source timer is outside its range")
            timers = timers + 1
        end

        if id == "portal_desolation_entry_nicolae_slug" then
            if record.kind == effects.ITEM and
                record.arguments.kind_id == item_ids.CORPSE_BODY and
                record.arguments.base_id == monster_ids.MONS_DART_SLUG and
                record.arguments.never_decay then
                slug_bodies = slug_bodies + 1
            elseif record.kind == effects.DELAYED_DECAY then
                slug_triggers = slug_triggers + 1
            end
        end
    end

    harness.equal(timers, 1, id .. " must have one timed gate")

    if id == "portal_desolation_entry_nicolae_slug" then
        harness.equal(slug_bodies, 1,
            "source slug entrance places one preserved corpse")
        harness.equal(slug_triggers, 1,
            "source slug entrance arms one sight decay trigger")
    end
end

-- A Vaults special-room chance is already settled by its controller.
-- Both portal families therefore need tag selection without a second
-- chance check; their ordinary Vaults CHANCE is intentionally zero.
local function special_room_candidates()
    local random = {}

    -- Roll zero would accept a positive CHANCE, exposing accidental rolls.
    function random:roll(_bound)
        return 0
    end

    local context = {
        branch_id = branches.BRANCH_VAULTS,
        depth = 1,
        branch_bottom = 5,
        absolute_depth = 20,
        layout_family = "vaults",
    }

    for _, tag in ipairs({
        tags.VAULTS_WIZLAB,
        tags.VAULTS_DESOLATION,
    }) do
        harness.equal(selection.choose_tag(random, tag, context), nil,
            tag .. " ordinary Vaults chance is suppressed")

        context.ignore_chance = true
        harness.truthy(selection.choose_tag(random, tag, context),
            tag .. " special-room choice is selectable")
        context.ignore_chance = nil
    end
end

-- Verify all three domain families and static metadata. The selector
-- needs the metadata before any source-position hook can run.
function test.run()
    local entrances = maps_in("vaults/desolation_entry")
    local ruins = maps_in("vaults/desolation_ruin")
    local floors = maps_in("vaults/desolation")
    local all = {}

    harness.equal(#entrances, 9, "Desolation source entrances")
    harness.equal(#ruins, 54, "Desolation source ruins")
    harness.equal(#floors, 3, "Desolation source floors")

    for _, group in ipairs({ entrances, ruins, floors }) do
        for _, map in ipairs(group) do
            all[#all + 1] = map
        end
    end

    harness.equal(digest(all), 747425363,
        "all 66 Desolation source MAP layouts")

    for _, map in ipairs(entrances) do
        harness.truthy(map.tags.uniq_desolation and
            map.tags.vaults_desolation and
            map.tags.chance_desolation,
            map.id .. " lacks source portal tags")
        harness.equal(map.chances[1].chance, 500,
            map.id .. " source entrance chance")

        harness.truthy(eligibility.depth(map, {
            branch_id = branches.BRANCH_ELF,
            depth = 1,
            branch_bottom = 3,
            absolute_depth = 20,
        }), map.id .. " cannot appear in Elf")
        harness.truthy(not eligibility.depth(map, {
            branch_id = branches.BRANCH_ELF,
            depth = 3,
            branch_bottom = 3,
            absolute_depth = 22,
        }), map.id .. " leaked to Elf:$")
        harness.truthy(not eligibility.depth(map, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = 10,
            branch_bottom = 15,
            absolute_depth = 10,
        }), map.id .. " leaked to Dungeon")
        harness.equal(depth.chance(map,
            branches.BRANCH_VAULTS, 1, 5, 20), 0,
            map.id .. " must skip ordinary Vaults chance")
        place_entrance(map.id)
    end

    for _, map in ipairs(ruins) do
        harness.truthy(map.tags.desolation_ruin,
            map.id .. " lacks source ruin tag")
        harness.equal(#map.depths, 0,
            map.id .. " leaked outside source SUBVAULT selection")
        place_ruin(map.id)
    end

    local candidates = level.candidates({})
    special_room_candidates()

    harness.equal(#candidates, 3, "complete floor candidates")
    harness.equal(candidates[1].id, "desolation_of_salt",
        "stable source ID selection order")
    harness.equal(candidates[3].id, "nicolae_desolation_temple",
        "stable source ID selection order")

    for _, candidate in ipairs(candidates) do
        generate(candidate.id)
    end
end

return test
