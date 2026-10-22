-- The source timed_msg policy belongs to the live Sewer system. This
-- fixture calls that production system directly, so it cannot drift into
-- a second implementation of the rust-speed schedule.
local component = require("constants.component")
local harness = require("tests.harness")
local signals = require("constants.world_signals")
local system = require("systems.world_sewer_portals")
local terrain = require("constants.terrain")

local test = {}
local context = {}

-- One fixed 600-turn source draw is enough to reach each messaging band.
-- The component names come from production constants and its schema.
local function new_context()
    return setmetatable({
        time = 0,
        gate = terrain.DNGN_ENTER_SEWER,
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
            duration_turns = 600,
            created_aut = 0,
            expires_aut = 6000,
            next_notice_aut = 500,
            announced = false,
            final_warning = false,
            spent = false,
        },
    }, { __index = context })
end

-- The player is the only actor whose accepted action advances this timer.
function context:player()
    return 1
end

-- The position and saved drain component are the only ECS reads needed by
-- the production timer; no duplicate component schema lives in this test.
function context:get(entity, id)
    if entity == 1 and id == component.POSITION then
        return self.position
    end

    if entity == 2 and id == component.WORLD_SEWER_PORTAL then
        return self.portal
    end

    return nil
end

-- The focused world has one drain, so every query finds that same owner.
function context:query(ids)
    harness.equal(ids[1], component.WORLD_SEWER_PORTAL,
        "Sewer system queried its clock")

    return { 2 }
end

-- Real ECS writes retain announcement and next-check state across actions.
function context:set(entity, id, value)
    harness.equal(entity, 2, "Sewer system updated its drain entity")
    harness.equal(id, component.WORLD_SEWER_PORTAL,
        "Sewer system updated its clock component")

    self.portal = value
end

-- The scheduler passes start-of-action time, just as the game runtime does.
function context:aut()
    return self.time
end

-- No accepted portal travel masks expiry in this timing-only fixture.
function context:signals(id)
    harness.equal(id, signals.PORTAL_TRAVEL,
        "Sewer system checked the travel signal")

    return {}
end

-- Messages stay in order so the source discovery, cadence, and collapse
-- wording can each be asserted without simulating the terminal.
function context:emit(_, message)
    self.messages[#self.messages + 1] = message
end

-- The drain is on the test grid until the source deadline expires.
function context:cell()
    return self.gate
end

-- Expiry mutates only the feature at this portal's saved coordinates.
function context:set_cell(_, x, y, feature)
    harness.equal(x, 10, "Sewer drain x")
    harness.equal(y, 10, "Sewer drain y")

    self.gate = feature
end

-- The player stands on the drain for the visible collapse message.
function context:visible()
    return true
end

-- Run one accepted ten-aut action at an explicit start time. Large gaps
-- represent actions taken between notices, not a new duration draw.
local function action_at(ctx, start_aut)
    ctx.time = start_aut
    system.update(ctx, ctx:player(), 10)
end

-- Source checks start after fifty turns, speed up as the deadline nears,
-- and emit a distinct warning before the final visible collapse.
function test.run()
    local ctx = new_context()

    action_at(ctx, 0)
    harness.equal(ctx.messages[1],
        "You hear the sound of rushing water.",
        "Sewer source discovery sound")
    harness.equal(ctx.messages[2],
        "There is an entrance to a sewer on this level. " ..
            "Hurry and find it before the portal rusts away!",
        "Sewer source discovery warning")

    action_at(ctx, 490)
    harness.equal(#ctx.messages, 2,
        "no rust notice at the exact first check")

    action_at(ctx, 500)
    harness.equal(ctx.messages[3],
        "You hear the slow rusting of a drain.",
        "Sewer slow rust notice")

    action_at(ctx, 3510)
    harness.equal(ctx.messages[4],
        "You hear the quick rusting of a drain.",
        "Sewer late rust notice")

    action_at(ctx, 5910)
    harness.equal(ctx.messages[5],
        "You hear the drain falling apart.",
        "Sewer final pre-collapse warning")

    action_at(ctx, 5920)
    harness.equal(#ctx.messages, 5,
        "no rust notice after the final warning")

    action_at(ctx, 5990)
    harness.equal(ctx.messages[6], "The drain falls to bits.",
        "Sewer visible collapse")
    harness.equal(ctx.gate, terrain.DNGN_EXPIRED_PORTAL,
        "Sewer expired feature")
    harness.truthy(ctx.portal.spent,
        "Sewer saved clock becomes spent")
end

return test
