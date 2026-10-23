-- This fixture drives the production Ice Cave ECS system directly. It
-- imports component IDs and the system, so message tests cannot drift into
-- a second timer implementation.
local component = require("constants.component")
local harness = require("tests.harness")
local signals = require("constants.world_signals")
local system = require("systems.world_ice_cave_portals")
local terrain = require("constants.terrain")

local test = {}
local context = {}

-- A fixed source 600-turn clock reaches all five notice bands.
local function new_context()
    return setmetatable({
        time = 0,
        gate = terrain.DNGN_ENTER_ICE_CAVE,
        messages = {},
        position = {
            level_id = 1,
            x = 10,
            y = 10,
        },
        portal = {
            level_id = 1,
            x = 10,
            y = 10,
            expires_aut = 6000,
            next_notice_aut = 500,
            announced = false,
            final_warning = false,
            spent = false,
        },
    }, { __index = context })
end

-- The system only advances on accepted player actions.
function context:player()
    return 1
end

-- Silence reads the player status; the timer reads its own ECS state.
function context:get(entity, id)
    if entity == 1 and id == component.POSITION then
        return self.position
    end

    if entity == 1 and id == component.PLAYER_STATUS then
        return self.player_status
    end

    if entity == 2 and id == component.WORLD_ICE_CAVE_PORTAL then
        return self.portal
    end

    return nil
end

-- One gate is enough to check this system's timing and state writes.
function context:query(ids)
    if ids[1] == component.WORLD_ICE_CAVE_PORTAL then
        return { 2 }
    end

    return {}
end

-- Store writes use the real component key, as game ECS writes do.
function context:set(entity, id, value)
    harness.equal(entity, 2, "Ice Cave timer entity")
    harness.equal(id, component.WORLD_ICE_CAVE_PORTAL,
        "Ice Cave timer component")
    self.portal = value
end

-- Scheduler time is the start of the action being processed.
function context:aut()
    return self.time
end

-- The base fixture has no accepted portal-travel signal.
function context:signals(id)
    harness.equal(id, signals.PORTAL_TRAVEL, "portal signal name")
    return self.travelling and { true } or {}
end

-- Preserve message order to check discovery, cadence, and closure.
function context:emit(_, message)
    self.messages[#self.messages + 1] = message
end

-- Grid reads distinguish a live portal from its expired feature.
function context:cell()
    return self.gate
end

-- Expiry mutates only the saved gate's grid cell.
function context:set_cell(_, x, y, feature)
    harness.equal(x, 10, "Ice Cave gate x")
    harness.equal(y, 10, "Ice Cave gate y")
    self.gate = feature
end

-- Visibility chooses source collapse text versus unseen vibration.
function context:visible()
    return self.can_see ~= false
end

-- Include the ten-aut action delta, just as the scheduler does.
local function action_at(ctx, start_aut)
    ctx.time = start_aut
    system.update(ctx, ctx:player(), 10)
end

-- Discovery and the fixed clock work without another random draw.
local function check_timeline()
    local ctx = new_context()

    action_at(ctx, 0)
    harness.equal(ctx.messages[1],
        "You feel a wave of frost pass over you.",
        "source frost discovery")
    harness.equal(ctx.messages[2],
        "There is an entrance to an ice cave on this level. " ..
            "Hurry and find it before the portal melts!",
        "source entrance warning")

    action_at(ctx, 490)
    harness.equal(#ctx.messages, 2, "first notice is not early")
    action_at(ctx, 500)
    harness.equal(ctx.messages[3],
        "You hear the faint crackling of a melting archway.",
        "first crackle notice")
    action_at(ctx, 5910)
    harness.equal(ctx.messages[4],
        "The crackling of melting ice is subsiding rapidly.",
        "final warning")
    action_at(ctx, 5990)
    harness.equal(ctx.messages[5],
        "The archway melts and disappears.",
        "source visible expiry")
    harness.equal(ctx.gate, terrain.DNGN_EXPIRED_PORTAL,
        "expired portal terrain")
    harness.equal(ctx.portal.closure_reason, "expiry",
        "separate expiry reason")
end

-- Notice wording depends on remaining time; hearing can be suppressed by
-- Silence without moving the next scheduled notice or replaying discovery.
local function check_bands_and_silence()
    for _, sample in ipairs({
        {
            remaining = 5500,
            adjective = "faint ",
        },
        {
            remaining = 4500,
            adjective = "",
        },
        {
            remaining = 3500,
            adjective = "steady ",
        },
        {
            remaining = 2000,
            adjective = "quick ",
        },
        {
            remaining = 500,
            adjective = "loud ",
        },
    }) do
        local ctx = new_context()

        ctx.portal.announced = true
        ctx.portal.next_notice_aut = 0
        action_at(ctx, 6000 - sample.remaining - 10)
        harness.equal(ctx.messages[1],
            "You hear the " .. sample.adjective ..
                "crackling of a melting archway.",
            "source ice crackle band " .. sample.remaining)
    end

    local silenced = new_context()

    silenced.player_status = { silence_aut = 1000 }
    action_at(silenced, 0)
    harness.equal(#silenced.messages, 0, "Silence hides discovery")

    silenced.player_status = nil
    action_at(silenced, 500)
    harness.equal(silenced.messages[1],
        "You hear the faint crackling of a melting archway.",
        "notice resumes after Silence")
end

-- Call each production behavior separately so a failure names its phase.
function test.run()
    check_timeline()
    check_bands_and_silence()
end

return test
