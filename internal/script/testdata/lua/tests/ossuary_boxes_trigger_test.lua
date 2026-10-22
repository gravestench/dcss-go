-- Theory of operation: the boxes map supplies real oriented marker
-- records. The production trigger owner gives every ':' cell one shared
-- group, so stepping on any of them opens every surviving a/b wall once.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local level_policy = require("policy.generation.ossuary.level")
local saved_boxes = require("policy.save.ossuary_boxes")
local terrain = require("constants.terrain")
local triggers = require("policy.world.vault_triggers")
local trigger_ids = require("constants.vault_triggers")

local test = {}

-- A deterministic generation context supplies the real map and its
-- substitutions; the test does not invent a second marker schema.
local function random_context()
    local state = 83
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    function context:random(_, bound)
        state = (state * 48271) % 2147483647

        return state % bound
    end

    return context
end

-- Keep ECS storage real. Only the not-yet-installed grid and message sink
-- need a proxy while this Lua rule test runs outside a game session.
local function game_context(ctx, level)
    local game = setmetatable({
        messages = {},
    }, { __index = ctx })
    local player = ctx:create()

    function game:player()
        return player
    end

    function game:cell(_, x, y)
        return level.cells[y + 1][x + 1]
    end

    function game:set_cell(_, x, y, feature)
        level.cells[y + 1][x + 1] = feature
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return game
end

-- The same source record indexes are used by the live population pass and
-- by save validation; assigning them here mirrors Go's level decode.
local function source_level()
    local result = level_policy.generate(random_context(), {
        layout_id = "ossuary_boxes_badplayer",
    })
    local level = result.level

    for index, record in ipairs(level.vault_records) do
        record.index = index
        record.source_id = record.vault_id
    end

    return level
end

-- One player move changes every linked wall and consumes all trigger
-- siblings. A second move cannot replay the callback or message.
function test.run(ctx)
    local level = source_level()
    local game = game_context(ctx, level)
    local trigger_records = {}
    local wall_records = {}

    for _, record in ipairs(level.vault_records) do
        if record.kind == effects.MARKER and
            record.identity == trigger_ids.OSSUARY_BOXES_OPEN then
            trigger_records[#trigger_records + 1] = record
            triggers.materialize(game, level, record)
        elseif record.kind == effects.MARKER and
            record.identity == trigger_ids.OSSUARY_BOXES_WALL then
            wall_records[#wall_records + 1] = record
        end
    end

    harness.truthy(#trigger_records > 1,
        "source has synchronized trigger cells")
    harness.truthy(#wall_records > 1,
        "source has linked disappearing walls")

    saved_boxes.validate(game, { levels = { level } })

    local first = trigger_records[1]

    triggers.enter(game, game:player(), {
        level_id = level.id,
        x = first.x,
        y = first.y,
    })

    for _, wall in ipairs(wall_records) do
        harness.equal(game:cell(level.id, wall.x, wall.y),
            terrain.DNGN_FLOOR,
            "one trigger opens every linked source wall")
    end

    harness.equal(#game:query({ component.WORLD_VAULT_TRIGGER }), 0,
        "one event consumes the whole trigger group")
    harness.equal(#game.messages, 1, "one wall-opening message")
    harness.equal(game.messages[1],
        "There is a click, and some walls slide away!",
        "source wall-opening message")

    local second = trigger_records[2]

    triggers.enter(game, game:player(), {
        level_id = level.id,
        x = second.x,
        y = second.y,
    })

    harness.equal(#game.messages, 1, "spent group stays silent")

    saved_boxes.validate(game, { levels = { level } })

    -- A partial terrain change cannot be produced by the callback. The
    -- validator must reject it even after every trigger was consumed.
    local wall = wall_records[1]

    game:set_cell(level.id, wall.x, wall.y,
        terrain.DNGN_STONE_WALL)

    local okay = pcall(saved_boxes.validate, game, {
        levels = { level },
    })

    harness.truthy(not okay, "partial wall state is not restorable")
end

return test
