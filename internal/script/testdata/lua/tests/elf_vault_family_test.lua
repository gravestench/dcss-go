-- Pin the complete Elf source category before a narrow selector can hide
-- missing maps. These counts use the effective mod catalog, not a roster.
local categories = require("constants.catalog")
local branches = require("ids.branches")
local harness = require("tests.harness")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local primary = require("policy.generation.vaults.primary")
local extra = require("policy.generation.vaults.extra")
local used = require("policy.generation.vaults.used")
local generated = require("policy.generation.generated")
local saved_vaults = require("policy.save.vaults")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Every source map gets the same deterministic placement stream so a
-- failure identifies its own directive, substitution, or helper pool.
local function random_context()
    local value = 83
    local context = {}

    -- Match the production builder's two-word RNG interface with a
    -- reproducible stream for independent placements.
    function context:random_u64()
        value = (value * 48271) % 2147483647
        local high = value

        value = (value * 48271) % 2147483647

        return high, value
    end

    return context
end

-- The effective catalog must be executable, not merely parseable. Mapless
-- controllers run in the later floor-primary stage and are excluded here.
local function place_all_maps(expected)
    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if expected[definition.family] and #definition.rows > 0 then
            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_ELF,
                depth = definition.family == "elf_end" and 3 or 2,
                branch_bottom = 3,
                absolute_depth = 16,
                name = "Player",
            }
            local okay, map = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(map))
            harness.truthy(map and #map.occupied > 0,
                id .. " placed no authored cells")

            if definition.family == "elf_blades" then
                for _, operation in ipairs(definition.operations) do
                    if operation.kind == directives.SUBVAULT then
                        harness.equal(#map.vault_ids, 1,
                            id .. " has one blade-entry helper")
                        local helper = vaults.get(map.vault_ids[1])

                        harness.truthy(helper.tags[tags.ELF_BLADE_ENTRY],
                            id .. " selected its tagged helper")
                    end
                end
            end

            count = count + 1
        end
    end

    harness.equal(count, 114, "all source Elf MAPs place")
end

-- Saved Hall history must retain its actual blade-entry helper. A spread
-- controller must retain the child it chose, not a later unrelated room.
local function saved_helper_contract()
    local context = {}

    -- The common save pass queries live Slime seals; this Elf-only input
    -- has no such entities.
    function context:query()
        return {}
    end

    local helper_id
    local misc_id

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.tags[tags.ELF_BLADE_ENTRY] and not helper_id then
            helper_id = id
        end

        if definition.family == "elf" and
            definition.tags[tags.MISC_ELF_VAULT] and not misc_id then
            misc_id = id
        end
    end

    local hall_id = "elven_hall_of_blades_hangedman_original"
    local hall = {
        id = "Elf:2",
        branch_id = branches.BRANCH_ELF,
        local_depth = 2,
        vault_id = hall_id,
        vault_ids = { hall_id },
        vault_records = {},
    }

    harness.falsy(pcall(saved_vaults.validate, context, {
        levels = { hall },
    }), "Hall without its blade-entry helper cannot restore")

    hall.vault_ids[2] = helper_id

    harness.truthy(pcall(saved_vaults.validate, context, {
        levels = { hall },
    }), "Hall with its tagged helper restores")

    local spread = {
        id = "Elf:1",
        branch_id = branches.BRANCH_ELF,
        local_depth = 1,
        vault_id = "elven_spread",
        vault_ids = { "elven_spread", misc_id },
        vault_records = {},
    }

    harness.falsy(pcall(saved_vaults.validate, context, {
        levels = { spread },
    }), "unrelated misc room cannot stand in for spread child")

    spread.vault_records[1] = {
        kind = effects.GENERATION_RULE,
        identity = "elven_spread_child",
        source_id = "elven_spread",
        arguments = {
            child_id = misc_id,
        },
    }

    harness.truthy(pcall(saved_vaults.validate, context, {
        levels = { spread },
    }), "recorded spread child restores")
end

-- Exercise the mapless primary through its real controller API. It must
-- place one room and save provenance before optional extras can be drawn.
local function spread_controller()
    local ctx = random_context()
    local builder = grid.new(ctx)

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    local player = {
        branch_id = branches.BRANCH_ELF,
        depth = 1,
        branch_bottom = 3,
        absolute_depth = 15,
    }
    local context = {
        branch_id = player.branch_id,
        depth = player.depth,
        branch_bottom = player.branch_bottom,
        absolute_depth = player.absolute_depth,
        primary_vault_family = "elf_arrival",
        primary_allow_dummy = true,
        primary_choice = { id = "elven_spread" },
        protected = {},
        required = {},
        player = player,
        used = used.new({}),
    }
    local placed = {}
    local selected = primary.place(ctx, builder, context, placed,
        extra.place)

    harness.equal(selected, "elven_spread", "spread primary selected")
    harness.equal(#placed, 1, "spread placed one source child")

    local child = placed[1]
    local definition = vaults.get(child.id)

    harness.truthy(definition.tags[tags.MISC_ELF_VAULT],
        "spread chose a tagged misc room")
    harness.equal(child.records[#child.records].arguments.child_id,
        child.id, "spread records its chosen child")
end

-- The branch declares one source PLACE family at each depth. The Elf:1
-- dummy participates in its weighted draw; later floors have no dummy.
local function primary_pools()
    local branch = register.get(categories.BRANCHES, branches.BRANCH_ELF)
    local expected = {
        [1] = 16,
        [2] = 4,
        [3] = 21,
    }

    for depth, count in pairs(expected) do
        local specification = primary.specification(branch, depth)
        local context = {
            branch_id = branches.BRANCH_ELF,
            depth = depth,
            branch_bottom = branch.depth,
            absolute_depth = branch.absolute_depth + depth - 1,
            primary_vault_family = specification.family,
            primary_allow_dummy = specification.allow_dummy,
        }

        harness.equal(#primary.candidates(context), count,
            "Elf:" .. depth .. " source PLACE pool")
    end
end

-- The source border-check stair replaces the provisional branch return.
-- A dummy or mapless choice leaves that provisional stair in place.
local function authored_arrival_landing()
    local builder = grid.new(random_context())
    local layout = {
        builder = builder,
        stairs = {
            {
                up = { x = 10, y = 10 },
            },
        },
    }
    local protected = {
        ["10:10"] = true,
    }
    local maps = {
        {
            id = "elf_arrival_001",
            exits = {
                { x = 20, y = 20, source = "{" },
            },
        },
    }

    builder:set(10, 10, "<")
    builder:set(20, 20, "<")

    local point = generated.prefer_authored_branch_up(layout, maps,
        "elf_arrival_001", protected)

    harness.equal(point.x, 20, "source arrival x")
    harness.equal(point.y, 20, "source arrival y")
    harness.equal(builder:cell(10, 10), ".", "provisional up cleared")
    harness.falsy(protected["10:10"], "provisional up unprotected")
    harness.falsy(generated.prefer_authored_branch_up(layout, maps,
        "elf_arrival_dummy", protected), "dummy keeps ordinary entry")
end

-- Every source NAME has exactly one owned family in the committed mod.
function test.run()
    vaults.load()

    local expected = {
        elf_arrival = 16,
        elf = 55,
        elf_blade_entry = 19,
        elf_blades = 4,
        elf_end = 21,
    }
    local counts = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if expected[definition.family] then
            counts[definition.family] = (counts[definition.family] or 0) + 1
        end
    end

    for family, count in pairs(expected) do
        harness.equal(counts[family], count, family .. " source count")
    end

    place_all_maps(expected)
    primary_pools()
    authored_arrival_landing()
    saved_helper_contract()
    spread_controller()
end

return test
