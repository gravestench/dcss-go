-- Live Wizard Lab tests use the production generated source floors and
-- event handlers. Only time, random draws, and message capture are
-- controlled locally; schemas and marker positions are never copied.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local rooms = require("policy.generation.wizlab.level")
local terrain = require("constants.terrain")
local wizlab = require("constants.wizlab")
local borgnjor = require("policy.world.wizlab.events.borgnjor")
local doroklohe = require("policy.world.wizlab.events.doroklohe")
local wucad = require("policy.world.wizlab.events.wucad")
local zonguldrok = require("policy.world.wizlab.events.zonguldrok")
local borgnjor_handler = require(
    "policy.world.wizlab.events.handlers.borgnjor")
local doroklohe_handler = require(
    "policy.world.wizlab.events.handlers.doroklohe")
local wucad_handler = require(
    "policy.world.wizlab.events.handlers.wucad")
local zonguldrok_handler = require(
    "policy.world.wizlab.events.handlers.zonguldrok")

local test = {}

-- Generate a real source floor, then give the event owner the same
-- one-based record indices used by Go population and save validation.
local function source_floor(ctx, id)
    local result = rooms.generate(ctx, {
        species_id = "SP_HUMAN",
        player_name = "Tester",
        layout_id = id,
    })
    local level = result.level

    for index, record in ipairs(level.vault_records) do
        record.index = index
        record.source_id = record.source_id or record.vault_id
    end

    return level
end

-- Materialize only the chosen family from its real transformed markers.
local function source_state(ctx, level, handler, id)
    local before = #ctx:query({ id })
    local markers = 0
    local staged = setmetatable({}, {
        __index = ctx,
    })

    function staged:aut()
        return 0
    end

    function staged:random()
        return 0
    end

    for _, record in ipairs(level.vault_records) do
        if handler.is_marker(record) then
            harness.equal(record.kind, effects.MARKER,
                "event source is a marker")
            handler.materialize(staged, level, record)
            markers = markers + 1
        end
    end

    local entities = ctx:query({ id })

    harness.truthy(markers > 0, "source event markers are present")
    harness.equal(#entities, before + 1,
        "one ECS owner for the source event family")

    return ctx:get(entities[#entities], id)
end

-- Drive a callback with deterministic source time and messages, while
-- preserving the real ECS and component lookup methods beneath it.
local function event_context(ctx)
    local messages = {}
    local proxy = setmetatable({}, {
        __index = ctx,
    })

    function proxy:aut()
        return 0
    end

    function proxy:player()
        return nil
    end

    function proxy:random(_, bound)
        if bound == wizlab.WUCAD_MESSAGE_CHANCE_DENOMINATOR then
            return 1
        end

        return 0
    end

    function proxy:emit(channel, message)
        messages[#messages + 1] = {
            channel = channel,
            text = message,
        }
    end

    return proxy, messages
end

-- Several glyph cells share a numbered Wucad impression. Speaking at
-- one must consume all cells in that synchronized source group.
local function test_wucad(ctx)
    local level = source_floor(ctx, wizlab.WUCAD_MAP_ID)
    local state = source_state(ctx, level, wucad_handler,
        component.WORLD_WIZLAB_WUCAD)
    local proxy, messages = event_context(ctx)
    local first
    local second

    for index, spot in ipairs(state.message_spot) do
        if spot == 1 then
            first = first or index

            if first ~= index then
                second = index
                break
            end
        end
    end

    harness.truthy(first and second,
        "source Wucad spot has synchronized cells")

    local position = {
        level_id = level.id,
        x = state.message_x[first],
        y = state.message_y[first],
    }

    harness.truthy(wucad.tick(proxy, state, position, 0, true),
        "first source message fires")
    harness.truthy(state.message_done[1],
        "source spot is now consumed")
    harness.equal(messages[1].text,
        wizlab.WUCAD_MESSAGE_TEXT[1],
        "source impression is displayed")

    position.x = state.message_x[second]
    position.y = state.message_y[second]

    harness.falsy(wucad.tick(proxy, state, position, 0, true),
        "second cell cannot replay the shared impression")
    harness.equal(#messages, 1,
        "one impression across synchronized cells")

    -- A mod that drops an entire numbered source group must fail before
    -- creating an event owner with an unreachable one-shot message.
    local broken = {
        id = level.id,
        vault_records = {},
    }
    local anchor

    for _, record in ipairs(level.vault_records) do
        if record.identity == wizlab.WUCAD_MONKS_MARKER then
            anchor = record
        end

        if not (type(record.identity) == "string" and
            record.identity:find("spot = 7", 1, true)) then
            broken.vault_records[#broken.vault_records + 1] = record
        end
    end

    harness.truthy(anchor, "source monk marker is present")

    local okay, reason = pcall(wucad_handler.materialize,
        proxy, broken, anchor)

    harness.falsy(okay, "missing source spot is rejected")
    harness.truthy(tostring(reason):find("message spot 7", 1, true),
        "error names the absent source spot")
end

-- Doroklohe's first source phase warns once and schedules the next
-- absolute deadline; the later collapse remains a separate phase.
local function test_doroklohe(ctx)
    local level = source_floor(ctx, wizlab.DOROK_MAP_ID)
    local state = source_state(ctx, level, doroklohe_handler,
        component.WORLD_WIZLAB_DOROKLOHE)
    local proxy, messages = event_context(ctx)
    local position = {
        level_id = level.id,
        x = 0,
        y = 0,
    }

    state.next_aut = 1

    harness.truthy(doroklohe.tick(proxy, state, position, 1),
        "first source countdown fires")
    harness.equal(state.phase, 2,
        "first warning does not drop the walls")
    harness.truthy(state.next_aut > 1,
        "next warning has a future deadline")
    harness.equal(#messages, 1,
        "warning is emitted once")
end

-- A lost soul cannot call another when it dies. This exercises the
-- production death callback and its saved actor provenance guard.
local function test_borgnjor(ctx)
    local level = source_floor(ctx, wizlab.BORGNJOR_MAP_ID)
    source_state(ctx, level, borgnjor_handler,
        component.WORLD_WIZLAB_BORGNJOR)
    local actor = harness.actor_with(ctx,
        component.WORLD_WIZLAB_EVENT_ACTOR, {
            level_id = level.id,
            vault_id = wizlab.BORGNJOR_MAP_ID,
            source_index = 1,
            kind = wizlab.EVENT_ACTOR_BORGNJOR,
        })

    harness.falsy(borgnjor.monster_died(ctx, actor, nil, {
        level_id = level.id,
    }), "lost soul death does not recurse")
end

-- The D door threshold uses the remaining G graves and killed count;
-- a source-born grave actor is the only death that may advance it.
local function test_zonguldrok(ctx)
    local level = source_floor(ctx, wizlab.ZONG_MAP_ID)
    local state = source_state(ctx, level, zonguldrok_handler,
        component.WORLD_WIZLAB_ZONGULDROK)
    local owner = ctx:query({ component.WORLD_WIZLAB_ZONGULDROK })[1]
    local actor = harness.actor_with(ctx,
        component.WORLD_WIZLAB_EVENT_ACTOR, {
            level_id = level.id,
            vault_id = wizlab.ZONG_MAP_ID,
            source_index = state.grave_indices[1],
            kind = wizlab.EVENT_ACTOR_ZONGULDROK,
        })
    local changed
    local proxy = setmetatable({}, {
        __index = ctx,
    })

    function proxy:player()
        return nil
    end

    state.count = #state.grave_active - 5
    state.killed = 3

    function proxy:query(ids)
        if ids[1] == component.WORLD_WIZLAB_ZONGULDROK then
            return { owner }
        end

        return ctx:query(ids)
    end

    function proxy:get(entity, id)
        if entity == nil then
            return nil
        end

        if entity == owner and
            id == component.WORLD_WIZLAB_ZONGULDROK then
            return state
        end

        return ctx:get(entity, id)
    end

    function proxy:set_cell(_, x, y, feature)
        changed = {
            x = x,
            y = y,
            feature = feature,
        }
    end

    function proxy:set()
    end

    function proxy:visible()
        return true
    end

    function proxy:emit()
    end

    zonguldrok.monster_died(proxy, actor, nil, {
        level_id = level.id,
    })

    harness.truthy(state.door_appeared,
        "source kill threshold opens the D door")
    harness.equal(changed.feature, terrain.DNGN_CLOSED_DOOR,
        "D marker becomes a closed door")
    harness.equal(changed.x, state.door_x,
        "door uses transformed source x")
    harness.equal(changed.y, state.door_y,
        "door uses transformed source y")
end

-- Exercise every family against its actual source map in one batch.
function test.run(ctx)
    test_wucad(ctx)
    test_doroklohe(ctx)
    test_borgnjor(ctx)
    test_zonguldrok(ctx)
end

return test
