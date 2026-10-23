-- The source moves the square around the player back to the center,
-- expanding that square around any touched vault. These tests exercise
-- the production shift planner with a deterministic Wastes sampler.
local abyss = require("constants.abyss")
local component = require("constants.component")
local harness = require("tests.harness")
local shift = require("policy.world.abyss.shift")
local population = require("policy.world.abyss.population")
local terrain = require("constants.terrain")
local monsters = require("ids.monsters")

local test = {}

-- A detached level plan stands in for ctx:region_plan. The two source
-- records are one vault: the second lies outside the basic radius 10.
local function plan(far_x)
    local cells = {}
    local known = {}
    local seen = {}
    local detected = {}

    for y = 0, abyss.HEIGHT - 1 do
        cells[y + 1] = {}
        known[y + 1] = {}
        seen[y + 1] = {}
        detected[y + 1] = {}

        for x = 0, abyss.WIDTH - 1 do
            cells[y + 1][x + 1] = terrain.DNGN_FLOOR
            known[y + 1][x + 1] = terrain.DNGN_UNSEEN
            seen[y + 1][x + 1] = false
            detected[y + 1][x + 1] = false
        end
    end

    cells[36][9] = terrain.DNGN_CRYSTAL_WALL
    known[36][9] = terrain.DNGN_CRYSTAL_WALL
    seen[36][9] = true

    return {
        cells = cells,
        known = known,
        seen = seen,
        detected_items = detected,
        local_depth = 1,
        vault_ids = { "test_vault" },
        vault_records = {
            {
                kind = "source_feature",
                vault_id = "test_vault",
                identity = terrain.DNGN_CRYSTAL_WALL,
                x = 8,
                y = 35,
            },
            {
                kind = "source_feature",
                vault_id = "test_vault",
                identity = terrain.DNGN_FLOOR,
                x = far_x,
                y = 35,
            },
        },
        stairs = {},
        cell_colours = {},
        spawn_exclusions = {},
        actor_moves = {},
        actor_retire = {},
    }
end

-- The Wastes sampler reads source hash and Worley primitives from ctx;
-- fixed values keep this test about copying rather than terrain noise.
local function context(far_x)
    local world = {}
    local level = plan(far_x)
    local player = {}

    function world:player()
        return player
    end

    function world:region_plan(id)
        harness.equal(id, abyss.LEVEL_ID)

        return level
    end

    function world:get(entity, name)
        harness.equal(entity, player)

        if name == component.PLAYER_RUNES then
            return { collected = {} }
        end

        harness.equal(name, component.POSITION)

        return {
            level_id = abyss.LEVEL_ID,
            x = 8,
            y = 35,
        }
    end

    -- Shift sees the player as the sole positioned actor in this fixture.
    function world:query()
        return { player }
    end

    function world:worley()
        return {
            distance = { 0.25, 0.75 },
            id = { 0, 1 },
        }
    end

    function world:hash3_quotient_mod()
        return 500
    end

    function world:random(_, bound)
        return bound - 1
    end

    function world:random_u64()
        return 0, 17
    end

    return world, player
end

-- Shifting by 32 columns changes the source origin by minus 32.
-- A touched vault moves as one, including its distant second record.
function test.preserves_whole_vault()
    local ctx, player = context(25)
    local state = {
        branch_depth = 1,
        morph_depth = 100,
        world_x = 1000,
        world_y = 1000,
        sample_queue = {
            {
                x = 8,
                y = 35,
                change = 123456,
                feature = terrain.DNGN_CRYSTAL_WALL,
            },
        },
        borrowed_layout = { { terrain.DNGN_FLOOR } },
        shift_count = 0,
    }
    local region, updated = shift.plan(ctx, state, player)

    harness.equal(updated.world_x, 968)
    harness.equal(updated.shift_count, 1)
    harness.equal(region.cells[36][41], terrain.DNGN_CRYSTAL_WALL)
    harness.equal(region.known[36][41], terrain.DNGN_CRYSTAL_WALL)
    harness.truthy(region.seen[36][41])
    harness.equal(region.vault_records[1].x, 40)
    harness.equal(region.vault_records[2].x, 57)
    harness.equal(region.vault_ids[1], "test_vault")
    harness.equal(region.actor_moves[1].x, abyss.CENTRE_X)

    local preserved_change

    for _, sample in ipairs(updated.sample_queue) do
        if sample.x == abyss.CENTRE_X and
            sample.y == abyss.CENTRE_Y then
            preserved_change = sample.change
            break
        end
    end

    harness.equal(preserved_change, 123456)
end

-- The source's old move loop can truncate a vault at the edge. The new
-- transaction rejects that candidate before mutating the saved region.
function test.rejects_clipped_vault()
    local ctx, player = context(70)
    local state = {
        branch_depth = 1,
        morph_depth = 100,
        world_x = 1000,
        world_y = 1000,
        sample_queue = {},
        borrowed_layout = { { terrain.DNGN_FLOOR } },
        shift_count = 0,
    }

    local okay = pcall(function()
        shift.plan(ctx, state, player)
    end)

    harness.falsy(okay)

    harness.equal(state.shift_count, 0)
end

-- The live action stages one region, then moves an item and retires
-- off-window actors and clouds. No world mutation happens in this fake
-- context; the assertions inspect the exact requests to the host API.
function test.stages_entity_lifecycle()
    local ctx, player = context(25)
    local monster = {}
    local item = {}
    local cloud = {}
    local replaced
    local moved_item
    local destroyed = {}

    function ctx:query(names)
        if names[1] == component.ACTOR then
            return { player, monster }
        end

        if names[1] == component.POSITION then
            return { player, monster, item }
        end

        if names[1] == component.WORLD_CLOUD then
            return { cloud }
        end

        return {}
    end

    function ctx:get(entity, name)
        if name == component.ACTOR and entity == monster then
            return { kind_id = monsters.MONS_RAT }
        end

        if name == component.POSITION then
            if entity == player then
                return {
                    level_id = abyss.LEVEL_ID,
                    x = 8,
                    y = 35,
                }
            end

            if entity == monster then
                return {
                    level_id = abyss.LEVEL_ID,
                    x = 60,
                    y = 35,
                }
            end

            if entity == item then
                return {
                    level_id = abyss.LEVEL_ID,
                    x = 9,
                    y = 35,
                }
            end
        end

        if name == component.WORLD_CLOUD and entity == cloud then
            return {
                level_id = abyss.LEVEL_ID,
                x = 60,
                y = 35,
            }
        end
    end

    function ctx:has(entity, name)
        return name == component.ACTOR and
            (entity == player or entity == monster)
    end

    function ctx:replace_region(_, region)
        replaced = region
    end

    function ctx:mark_region_records(_, records)
        harness.equal(#records.entries, 0)
    end

    function ctx:add_region_actors(_, count)
        harness.equal(count, 0)
    end

    function ctx:set(entity, name, fields)
        harness.equal(entity, item)
        harness.equal(name, component.POSITION)
        moved_item = fields
    end

    function ctx:destroy(entity)
        destroyed[entity] = true
    end

    local state = {
        branch_depth = 1,
        morph_depth = 100,
        world_x = 1000,
        world_y = 1000,
        sample_queue = {},
        borrowed_layout = { { terrain.DNGN_FLOOR } },
        shift_count = 0,
    }
    -- This case checks region and entity movement. The whole-game test
    -- exercises the real population pass against an Akara world.
    local materialize = population.materialize

    population.materialize = function()
        return 0
    end

    local okay, updated = pcall(shift.apply, ctx, state, player)

    population.materialize = materialize

    if not okay then
        error(updated)
    end

    harness.truthy(replaced)
    harness.equal(replaced.actor_retire[1], monster)
    harness.equal(moved_item.x, 41)
    harness.equal(moved_item.y, 35)
    harness.truthy(destroyed[monster])
    harness.truthy(destroyed[cloud])
    harness.equal(updated.shift_count, 1)
end

-- Keep the policy runner's single entry point while each case remains
-- named, small, and independently readable above.
function test.run()
    test.preserves_whole_vault()
    test.rejects_clipped_vault()
    test.stages_entity_lifecycle()
end

return test
