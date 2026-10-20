-- Aquarium serials share source biomes and nested bridge helpers.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local settings = require("constants.vault_settings")
local tags = require("constants.vault_tags")
local resolve = require("policy.generation.vaults.specs.resolve")
local monsters = require("ids.monsters")

local test = {}

-- The controller chooses one pool width, then requests all five map groups
-- in source order. The setting travels only with this level's child context.
local function controller_contract()
    local vault = catalog.get(ids.serial_aquarium)
    local requested = {}
    local api = {
        context = {
            player = {},
        },
    }

    function api:roll()
        return 0
    end

    function api:place_maps(tag, count)
        requested[#requested + 1] = { tag = tag, count = count }
    end

    hooks.run(vault, "place_aquarium", api)

    harness.equal(api.context.player.settings[settings.AQUARIUM_POOL_SIZE],
        0, "source thin pool setting")
    harness.equal(#requested, 5, "five source aquarium groups")
    harness.equal(requested[1].tag, tags.AQUARIUM_BRIDGE,
        "bridge group first")
    harness.equal(requested[1].count, 1, "minimum bridge count")
    harness.equal(requested[2].count, 2, "minimum window count")
    harness.equal(requested[3].count, 1, "minimum view count")
    harness.equal(requested[4].count, 0, "minimum balcony count")
    harness.equal(requested[5].count, 0, "minimum pool count")
end

-- Every source definition must have a separate committed DES path. A
-- top-level bridge also exercises SUBVAULT selection and shared biome setup.
local function complete_family_places()
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if id:match("^aquarium_") then
            count = count + 1
            local vault = catalog.get(id)

            harness.truthy(#vault.rows > 0, "aquarium MAP exists " .. id)

            if not id:match("^aquarium_subvault_") then
                local builder = grid.new({})

                function builder:roll()
                    return 0
                end

                local placed = placement.place(nil, builder, vault, {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 8,
                    absolute_depth = 8,
                    branch_bottom = 15,
                    settings = {
                        [settings.AQUARIUM_POOL_SIZE] = 1,
                    },
                })

                harness.truthy(placed, "aquarium piece places " .. id)
            end
        end
    end

    harness.equal(count, 52, "complete source aquarium child count")
end

-- The shared setup chooses one of the source's nine Dungeon depth bands,
-- while Elf takes its own obelisk and lightning branch. Inspect emitted
-- rules without copying their declarations into the fixture.
local function every_biome_emits()
    local vault = catalog.get(ids.aquarium_window_1)
    local cases = {
        { depth = 2, expected = "butterfly" },
        { depth = 5, expected = "frilled lizard" },
        { depth = 8, expected = "electric eel" },
        { depth = 11, expected = "snapping turtle" },
        { depth = 14, expected = "large slime creature" },
        { depth = 17, expected = "polar bear" },
        { depth = 20, expected = "bat simulacrum", cloud = true },
        { depth = 23, expected = "fire bat" },
        { depth = 26, expected = "salamander", cloud = true },
        {
            depth = 26,
            branch_id = branches.BRANCH_ELF,
            expected = "diamond obelisk",
        },
    }

    for _, case in ipairs(cases) do
        local emitted = {}
        local markers = {}
        local api = {}

        function api:setting(name)
            harness.equal(name, settings.AQUARIUM_POOL_SIZE,
                "shared source pool setting")

            return 1
        end

        function api:branch_id()
            return case.branch_id or branches.BRANCH_DUNGEON
        end

        function api:absolute_depth()
            return case.depth
        end

        function api:emit(kind, argument)
            emitted[#emitted + 1] = { kind = kind, argument = argument }
        end

        function api:record(kind, arguments)
            markers[#markers + 1] = { kind = kind, arguments = arguments }
        end

        hooks.run(vault, "aquarium_setup.configure", api)

        local found = false

        for _, operation in ipairs(emitted) do
            if operation.kind == directives.KMONS and
                operation.argument:find(case.expected, 1, true) then
                found = true
            end
        end

        harness.truthy(found,
            "source biome creature at depth " .. case.depth)
        harness.equal(#markers, case.cloud and 1 or 0,
            "source cloud marker count at depth " .. case.depth)

        if case.cloud then
            harness.equal(markers[1].kind, effects.MARKER,
                "deep biome uses typed fog marker")
        end
    end
end

-- With only the forced p side open, the square must choose a wall, window,
-- or balcony for q/r/s and set clear glass at the two mixed corners.
local function square_bridge_keeps_forced_path()
    local vault = catalog.get(ids.aquarium_bridge_square)
    local emitted = {}
    local api = {}

    function api:roll(bound)
        return bound == 4 and 0 or bound - 1
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = { kind = kind, argument = argument }
    end

    hooks.run(vault, "aquarium_bridge.square", api)

    harness.equal(emitted[1].argument,
        "p : aquarium_subvault_bridge", "forced source bridge")
    harness.truthy(emitted[2].argument:find(
        "aquarium_subvault_wall:3", 1, true),
        "optional side keeps source helper weights")
    harness.equal(emitted[5].argument, "J = m",
        "mixed first corner has clear glass")
    harness.equal(emitted[8].argument, "M = m",
        "mixed last corner has clear glass")
end

-- Parse and project representative biomes through the real DES operation
-- stream, including nested helpers and source monster-name validation.
local function representative_biomes_place()
    local vault = catalog.get(ids.aquarium_bridge_square)

    for _, depth in ipairs({ 2, 5, 8, 11, 14, 17, 20, 23, 26 }) do
        local builder = grid.new({})

        function builder:roll()
            return 0
        end

        local placed = placement.place(nil, builder, vault, {
            branch_id = branches.BRANCH_DUNGEON,
            depth = depth,
            absolute_depth = depth,
            branch_bottom = 15,
            settings = {
                [settings.AQUARIUM_POOL_SIZE] = 2,
            },
        })

        harness.truthy(placed,
            "aquarium bridge places at source band " .. depth)
    end

    local elf_builder = grid.new({})

    function elf_builder:roll()
        return 0
    end

    local elf = placement.place(nil, elf_builder, vault, {
        branch_id = branches.BRANCH_ELF,
        depth = 1,
        absolute_depth = 20,
        branch_bottom = 3,
        settings = {
            [settings.AQUARIUM_POOL_SIZE] = 1,
        },
    })

    harness.truthy(elf, "Elf aquarium branch places")
end

-- The source writes body count in a monster name. Resolution must keep
-- that count as per-actor state instead of inventing four catalog kinds.
local function merged_slime_names_resolve()
    local sizes = {
        ["large slime creature"] = 2,
        ["very large slime creature"] = 3,
        ["enormous slime creature"] = 4,
        ["titanic slime creature"] = 5,
    }
    local site = {
        path = "vaults/serial/aquarium_bridge_square.des",
        vault_id = ids.aquarium_bridge_square,
        line = 1,
        directive = directives.KMONS,
        glyph = "w",
    }

    for name, size in pairs(sizes) do
        local selected = { name = name }

        resolve.validate_monster(selected, site)

        local resolved = resolve.monster({}, selected, 14, site)

        harness.equal(resolved.kind_id, monsters.MONS_SLIME_CREATURE,
            name .. " uses the source species")
        harness.equal(resolved.blob_size, size,
            name .. " retains its source body count")
    end
end

-- Test the controller and map set together so a source helper cannot be
-- omitted while its parent still parses.
function test.run()
    controller_contract()
    complete_family_places()
    every_biome_emits()
    square_bridge_keeps_forced_path()
    representative_biomes_place()
    merged_slime_names_resolve()
end

return test
