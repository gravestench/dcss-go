-- Theory of operation: the timed DES marker is a placement result, not a
-- timer started by stepping onto the gate. Dungeon population gives it one
-- ECS clock at the current global action time before any player travel.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local extra = require("policy.generation.vaults.extra")
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local portal = require("policy.world.ossuary.portal")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The bounded generation stream has repeatable placement, including the
-- source substitution that can move the gate among its sand cells.
local function random_context()
    local context = {}

    function context:random_u64()
        return 1, 1
    end

    return context
end

-- A real D:4 placement supplies the authored marker and final oriented
-- coordinate. No test-local marker declaration duplicates the source.
local function placed_entry()
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
    local placed, reason = extra.place(nil, builder,
        vaults.get("enter_ossuary_1"), {
            protected = {},
            required = {},
            player = player,
        })

    harness.truthy(placed, "source Ossuary entry: " .. tostring(reason))

    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, random_context(), 4)

    for index, record in ipairs(records) do
        record.index = index
        record.source_id = record.vault_id

        if record.kind == effects.MARKER and
            portal.is_marker(record) then
            return {
                id = 4,
                cells = cells,
                vault_records = records,
            }, record
        end
    end

    error("source Ossuary entry has no timed marker")
end

-- A clock installed at placement uses the already drawn marker lifetime.
-- Its deadline therefore advances while the gate is undiscovered.
function test.run(ctx)
    local level, record = placed_entry()
    local game = setmetatable({}, { __index = ctx })

    function game:aut()
        return 1234
    end

    portal.materialize(game, level, record)

    local entity, state = portal.at(game, level.id, record.x, record.y)
    local turns = portal.parse(record.identity)

    harness.truthy(entity, "population installed the Ossuary clock")
    harness.truthy(ctx:has(entity, component.WORLD_OSSUARY_PORTAL),
        "clock lives on the ECS portal entity")
    harness.equal(level.cells[record.y + 1][record.x + 1],
        terrain.DNGN_ENTER_OSSUARY, "timed marker belongs to gate")
    harness.equal(state.created_aut, 1234,
        "clock begins when Dungeon floor is populated")
    harness.equal(state.duration_turns, turns,
        "clock keeps the source lifetime draw")
    harness.equal(state.expires_aut, 1234 + turns * 10,
        "deadline is fixed before gate discovery")
end

return test
