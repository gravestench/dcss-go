-- Theory of operation: every effective source entrance must realize one
-- timed O marker and live gate. The marker's duration draw precedes
-- discovery; population copies it into one Akara clock without rerolling.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local portal = require("policy.world.wizlab.portal")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")
local wizlab = require("constants.wizlab")

local test = {}

-- Keep source layout draws deterministic while exercising real DES
-- substitutions, orientation, connection, and marker projection.
local function random_context()
    local context = {}

    function context:random_u64()
        return 1, 1
    end

    return context
end

-- A blank Depths floor can accept any source entrance. Only the map
-- catalog supplies its marker syntax and timer, never this fixture.
local function placed_entry(id)
    local builder = grid.new(random_context())

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, ".")
        end
    end

    local player = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 1,
        branch_bottom = 5,
        absolute_depth = 20,
    }
    local placed, reason = extra.place(nil, builder,
        vaults.get(id), {
            protected = {},
            required = {},
            player = player,
        })

    harness.truthy(placed, id .. " source gate: " .. tostring(reason))

    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, random_context(), 20)
    local marker

    for index, record in ipairs(records) do
        record.index = index
        record.source_id = record.vault_id

        if record.kind == effects.MARKER and
            portal.is_marker(record) then
            harness.truthy(not marker,
                id .. " produced more than one timed gate")
            marker = record
        end
    end

    harness.truthy(marker, id .. " lacks a timed source marker")

    return {
        id = 20,
        cells = cells,
        vault_records = records,
    }, marker
end

-- One tested gate becomes a saved component. The rest of the corpus
-- verifies that every source variant retains its real O feature.
function test.run(ctx)
    local example_level
    local example_record
    local count = 0

    for _, path in ipairs(mod.paths(
        "vaults/wizlab_entry", ".des")) do
        local id = path:match("([^/]+)%.des$")
        local level, record = placed_entry(id)
        local turns = portal.parse(record.identity)

        harness.truthy(turns >= wizlab.MIN_DURATION_TURNS and
            turns <= wizlab.MAX_DURATION_TURNS,
            id .. " drew source lifetime")
        harness.equal(level.cells[record.y + 1][record.x + 1],
            terrain.DNGN_ENTER_WIZLAB,
            id .. " marker belongs to its live gate")
        example_level = level
        example_record = record
        count = count + 1
    end

    harness.equal(count, 11, "all source Wizard Lab entrances")

    local game = setmetatable({}, {
        __index = ctx,
    })

    function game:aut()
        return 1234
    end

    portal.materialize(game, example_level, example_record)

    local entity, state = portal.at(game,
        example_level.id, example_record.x, example_record.y)

    harness.truthy(entity, "population installed one Wizard Lab clock")
    harness.truthy(ctx:has(entity, component.WORLD_WIZLAB_PORTAL),
        "clock lives on an ECS gate entity")
    harness.equal(state.created_aut, 1234,
        "clock begins when outside floor is populated")
    harness.equal(state.expires_aut,
        1234 + state.duration_turns * 10,
        "deadline retains the source duration")
end

return test
