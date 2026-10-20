-- Every committed overflow map should execute its DES operations and Lua
-- hooks through the same placement path used by a scheduled Dungeon floor.
-- The ordinary seed sweep reaches only a small weighted sample of this family.
local branches = require("ids.branches")
local catalog = require("policy.generation.altar.catalog")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local settings = require("constants.vault_settings")
local enchantments = require("constants.vault_monster_enchantments")

local test = {}

-- Isolate each map on a fresh open floor so a failed map identifies its own
-- content or hook rather than a conflict with an unrelated placed vault.
local function open_builder()
    local builder = grid.new({})
    local draw = 0

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    function builder:roll(bound)
        draw = draw + 1

        return draw % bound
    end

    return builder
end

-- The source tags declare the supported group sizes. Use the first sorted
-- size to exercise each map without a test-only list of 232 definitions.
local function altar_count(definition)
    local sizes = {}

    for tag in pairs(definition.tags) do
        local size = tag:match("^temple_overflow_generic_(%d+)$") or
            tag:match("^temple_overflow_(%d+)$")

        if size then
            sizes[#sizes + 1] = tonumber(size)
        end
    end

    table.sort(sizes)

    return sizes[1]
end

-- Pass a named god tag when a source hook selects a visual or guardian by
-- god. Generic maps receive only their count and remain god neutral.
local function map_tag(definition)
    local names = {}

    for tag in pairs(definition.tags) do
        if tag:match("^temple_overflow_[a-z_]+$") and
            not tag:match("^temple_overflow_generic_") then
            names[#names + 1] = tag
        end
    end

    table.sort(names)

    return names[1]
end

-- Hepliaklqana's source map has six mutually exclusive monster groups.
-- Exercise each actual DES hook against the real catalog definition, since
-- the catalog-wide pass below uses only D:10 for every map.
local function hero_groups_place()
    local id = "beargit_hepliaklqana_dungeon_heroes"
    local definition = catalog.get(id)
    local branches_and_depths = {
        { branches.BRANCH_DUNGEON, 3 },
        { branches.BRANCH_DUNGEON, 5 },
        { branches.BRANCH_DUNGEON, 8 },
        { branches.BRANCH_DUNGEON, 10 },
        { branches.BRANCH_DUNGEON, 13 },
        { branches.BRANCH_DEPTHS, 1 },
    }

    for _, branch_and_depth in ipairs(branches_and_depths) do
        local branch = branch_and_depth[1]
        local depth = branch_and_depth[2]
        local placed = extra.place(nil, open_builder(), definition, {
            protected = {},
            required = {},
            player = {
                branch_id = branch,
                depth = depth,
                absolute_depth = depth,
                branch_bottom = 15,
                map_tag = map_tag(definition),
                settings = {
                    [settings.OVERFLOW_ALTAR_COUNT] = 1,
                },
            },
        })

        harness.truthy(placed, id .. " places at " .. branch .. ":" .. depth)
    end
end

-- These source maps exercise distinct actor modifiers. Inspect the placed
-- record, since Go saves that record and later gives it to population.
local function preserved_monster_modifier(placed, field, expected)
    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER and record.arguments and
            record.arguments[field] == expected then
            return true
        end
    end

    return false
end

-- Exercise source transforms, emitted hooks, keyed effects, and connector
-- fit on every real definition; unsupported gameplay records stay typed.
function test.run()
    hero_groups_place()

    local placed_count = 0
    local failures = {}

    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)

        if #definition.rows > 0 then
            local count = altar_count(definition)

            harness.truthy(count, id .. " declares an overflow group size")

            local okay, placed, reason = pcall(extra.place, nil,
                open_builder(),
                definition, {
                    protected = {},
                    required = {},
                    player = {
                        branch_id = branches.BRANCH_DUNGEON,
                        depth = 10,
                        absolute_depth = 10,
                        branch_bottom = 15,
                        map_tag = map_tag(definition),
                        settings = {
                            [settings.OVERFLOW_ALTAR_COUNT] = count,
                        },
                    },
                })

            if not okay or not placed then
                failures[#failures + 1] = id .. ": " ..
                    tostring(placed or reason)
            else
                harness.equal(placed.id, id, "placed source map identity")

                if id == "elyvilon_altar_4" then
                    harness.truthy(preserved_monster_modifier(placed,
                        "patrolling", true), "patrol intent reaches level data")
                elseif id == "vehumet_statue" then
                    harness.truthy(preserved_monster_modifier(placed,
                        "hd", 3), "source hit dice reach level data")
                    harness.truthy(preserved_monster_modifier(placed,
                        "hp", 12), "source hit points reach level data")
                elseif id == "nicolae_ru_great_annihilating_truth" then
                    harness.truthy(preserved_monster_modifier(placed,
                        "permanent_enchantments", enchantments.PARALYSIS) or
                        preserved_monster_modifier(placed,
                            "permanent_enchantments", enchantments.CORONA),
                        "permanent status reaches level data")
                end

                placed_count = placed_count + 1
            end
        end
    end

    harness.equal(#failures, 0, table.concat(failures, "\n"))
    harness.truthy(placed_count > 200,
        "the audit exercised the complete overflow map family")
end

return test
