local branches = require("ids.branches")
local component = require("constants.component")
local harness = require("tests.harness")
local policy = require("policy.world.shoals_tide")
local system = require("systems.world_called_tide")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local player = 12
local state_id = "world.called_tide"

-- This fixture supplies the same grid and component reads as the runtime.
-- Water forms a connected channel from the corner sea to the caster, so the
-- source traversal can reach the nearby dry coast without faking visibility.
local function context()
    local ctx = {
        now = 20,
        height = 0,
        velocity = 2,
        last_aut = 0,
        cells = {},
        heights = {},
        state = {
            start_aut = 0,
            expires_aut = 1000,
        },
    }

    for x = 1, 4 do
        ctx.cells[x .. ":1"] = terrain.DNGN_DEEP_WATER
    end

    for y = 2, 4 do
        ctx.cells["4:" .. y] = terrain.DNGN_DEEP_WATER
    end

    ctx.heights["5:4"] = 12

    -- Return the fixed player so the active-system guard matches production.
    function ctx:player()
        return player
    end

    -- The test changes this clock to exercise ordinary and expired turns.
    function ctx:aut()
        return self.now
    end

    -- Position and saved spell state use their production component names.
    function ctx:get(entity, id)
        if id == component.POSITION then
            if entity == caster then
                return { level_id = 1, x = 4, y = 4 }
            end

            if entity == player then
                return { level_id = 1, x = 6, y = 4 }
            end
        end

        if entity == caster and id == state_id then
            return self.state
        end

        return nil
    end

    -- The system checks whether the active actor is a tide caller.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- A query sees only the live caster state in this one-caller fixture.
    function ctx:query(ids)
        if ids[1] == state_id and self.state then
            return { caster }
        end

        return {}
    end

    -- Expiry must remove the same component the query exposed.
    function ctx:remove(entity, id)
        if entity == caster and id == state_id then
            self.state = nil
        end
    end

    -- The isolated grid is a Shoals level, where the tide is permitted.
    function ctx:level_branch()
        return branches.BRANCH_SHOALS
    end

    -- The 9x9 grid gives the flood traversal real corner seeds.
    function ctx:level_size()
        return 9, 9
    end

    -- Clock reads mirror the level-owned Go tide state.
    function ctx:shoals_tide_clock()
        return self.height, self.velocity, self.last_aut
    end

    -- Persisting the clock lets assertions catch skipped elapsed turns.
    function ctx:set_shoals_tide_clock(_, height, velocity, last_aut)
        self.height = height
        self.velocity = velocity
        self.last_aut = last_aut
    end

    -- The coast has one intermediate elevation that current terrain hides.
    function ctx:shoals_height(_, x, y)
        return self.heights[x .. ":" .. y] or 0
    end

    -- This channel has no extra vault tide seeds.
    function ctx:marker_property()
        return nil
    end

    -- Pending water writes remain visible to later flood visits.
    function ctx:cell(_, x, y)
        if x < 0 or x > 8 or y < 0 or y > 8 then
            return nil
        end

        return self.cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    -- Record a live water change without rewriting the elevation table.
    function ctx:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    -- Keep stochastic door and receding-wave branches deterministic.
    function ctx:random()
        return 0
    end

    return ctx
end

-- Exercise clock acceleration, connected water, expiry, and catch-up in one
-- scenario so the pieces cannot quietly drift apart.
function test.run()
    local height, velocity = policy.advance(0, 2, true)

    harness.equal(height, 21, "a call accelerates the source tide clock")
    harness.equal(velocity, 21, "the first called step keeps its surge")

    height, velocity = policy.advance(height, velocity, true)

    harness.equal(height, 42, "a second called step approaches high tide")
    harness.equal(velocity, 21, "the surge remains fast outside the source deceleration margin")
    harness.equal(policy.at(0, 5, 4, { x = 4, y = 4 }, 2), 7,
        "local call strength falls with Chebyshev distance")

    local ctx = context()

    system.update(ctx, caster)

    harness.equal(ctx.height, 42, "Shoals level keeps the raw tide height")
    harness.equal(ctx.last_aut, 20, "Shoals clock records elapsed aut")
    harness.equal(ctx:cell(1, 5, 4), terrain.DNGN_SHALLOW_WATER,
        "connected coast floods when local tide overtops its elevation")
    harness.equal(ctx:cell(1, 7, 4), terrain.DNGN_FLOOR,
        "the first wave does not cross newly flooded ground instantly")

    ctx.now = 1000
    system.update(ctx, caster)

    harness.falsy(ctx.state, "an expired call is removed")
    harness.truthy(ctx.last_aut >= 1000,
        "the natural tide clock continues after the call ends")

    local catch_up = context()

    catch_up.now = 30
    catch_up.state.expires_aut = 15
    system.update(catch_up, caster)

    harness.equal(catch_up.height, 17,
        "catch-up applies the called step before ordinary receding steps")
    harness.falsy(catch_up.state,
        "catch-up clears the expired caller")
end

return test
