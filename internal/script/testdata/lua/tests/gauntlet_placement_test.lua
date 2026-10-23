-- Generate every authored parent through the real nested-vault runtime.
-- Parsing the corpus alone cannot catch helper fit, encounter, or marker
-- errors that occur only after a complete Gauntlet is composed.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local gauntlet = require("constants.gauntlet")
local harness = require("tests.harness")
local operations = require("policy.generation.vaults.operations")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

local arena_tags = {
    gauntlet.FIRST_TIER_TAG,
    gauntlet.SECOND_TIER_TAG,
    gauntlet.FIRST_TIER_77_TAG,
    gauntlet.SECOND_TIER_77_TAG,
}

-- Feed the production builder a repeatable draw stream without copying
-- any Gauntlet rules into this fixture.
local function seeded_context(seed)
    local value = seed
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647

        return 0, value
    end

    function context:random(_stream, bound)
        self:random_u64()

        return value % bound
    end

    return context
end

-- The parent is a full floor and its helpers are placed as local child
-- rectangles. Every declared parent must compose with one deterministic
-- source draw before we consider portal travel or save state.
local function place_parent(id)
    local context = seeded_context(37)
    local player = {
        branch_id = branches.BRANCH_GAUNTLET,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 13,
    }
    local builder = grid.new(context)
    local okay, result = pcall(placement.place, context, builder,
        vaults.get(id), player, {
            whole_level = true,
        })

    harness.truthy(okay,
        id .. " failed to compose: " .. tostring(result))
    harness.equal(result.id, id,
        id .. " lost its parent source identity")
end

-- Run every helper's actual operation stream, including source hook
-- expansion, under every tier tag it advertises. A parent seed alone
-- samples only some helpers from the complete source corpus.
local function expand_helper(definition, tag)
    local width = 0
    local cells = {}

    for _, row in ipairs(definition.rows) do
        width = math.max(width, #row)
    end

    for y, row in ipairs(definition.rows) do
        cells[y] = {}

        for x = 1, width do
            local glyph = row:sub(x, x)

            cells[y][x] = glyph == "" and " " or glyph
        end
    end

    local builder = grid.new(seeded_context(73))
    local player = {
        branch_id = branches.BRANCH_GAUNTLET,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 13,
    }
    local okay, records = pcall(operations.apply,
        definition, cells, builder, 1, player, nil, {
            tag = tag,
            ordinal = 1,
            settings = {},
        })

    harness.truthy(okay,
        definition.id .. " failed with tag " .. tag .. ": " ..
        tostring(records))

    if tag == gauntlet.EXIT_TAG then
        local exits = 0

        -- Operation records are still helper-local declarations here.
        -- The parent-placement and game tests verify their coordinates
        -- after the child rectangle is embedded in a complete floor.
        for _, record in ipairs(records) do
            if record.directive == directives.KFEAT and
                record.targets:find("<", 1, true) and
                features.named_vault_terrain[record.identity] ==
                    terrain.DNGN_EXIT_GAUNTLET then
                exits = exits + 1
            end
        end

        harness.equal(exits, 1,
            definition.id .. " boss room needs one live return arch")
    end
end

-- Discovery uses the production catalog rather than a second list of
-- source IDs in the test. A sparse mod may add another complete parent.
function test.run()
    vaults.load()
    local parents = {}
    local arenas = 0
    local exits = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == "gauntlet" then
            parents[#parents + 1] = id
        elseif definition.family == gauntlet.ARENA_FAMILY then
            arenas = arenas + 1

            for _, tag in ipairs(arena_tags) do
                if definition.tags[tag] then
                    expand_helper(vaults.get(id), tag)
                end
            end
        elseif definition.family == gauntlet.EXIT_FAMILY then
            exits = exits + 1
            expand_helper(vaults.get(id), gauntlet.EXIT_TAG)
        end
    end

    harness.equal(#parents, 10, "complete Gauntlet parent layouts")
    harness.equal(arenas, 43, "source arena helpers")
    harness.equal(exits, 6, "source minotaur exits")

    for _, id in ipairs(parents) do
        place_parent(id)
    end
end

return test
