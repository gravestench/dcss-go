-- Run, rest, and explore decisions use the same public map projection that
-- the terminal will pass to production Lua, rather than a second grid API.
local automation = require("policy.input.automation")
local commands = require("policy.input.commands")
local features = require("constants.terrain")
local harness = require("tests.harness")
local modes = require("constants.automation")
local play = require("policy.input.play")

local test = {}

-- All cells begin visible and walkable; one caller mutation changes one
-- reason to stop so policy behavior is clear without a generated map.
local function open_view()
    local cells = {}

    for _ = 1, 49 do
        cells[#cells + 1] = {
            feature = features.DNGN_FLOOR,
            state = 2,
            walkable = true,
        }
    end

    return {
        width = 7,
        height = 7,
        player_x = 3,
        player_y = 3,
        hp = 10,
        max_hp = 10,
        mp = 5,
        max_mp = 5,
        can_recover_hp = true,
        can_recover_mp = true,
        can_cross_lava = false,
        can_cross_deep_water = false,
        cells = cells,
        entities = {},
        clouds = {},
    }
end

-- The fixture's index is the same row-major, zero-coordinate contract as
-- the game's View.Cells, with only Lua's array index adding one.
local function cell(view, x, y)
    return view.cells[y * view.width + x + 1]
end

-- The source binds uppercase vi keys and shifted cursor keys to all eight
-- directions, while `5` and `o` begin their distinct automatic intents.
local function source_keys()
    local bindings = {
        { key = "H", dx = -1, dy = 0 },
        { key = "J", dx = 0, dy = 1 },
        { key = "K", dx = 0, dy = -1 },
        { key = "L", dx = 1, dy = 0 },
        { key = "Y", dx = -1, dy = -1 },
        { key = "U", dx = 1, dy = -1 },
        { key = "B", dx = -1, dy = 1 },
        { key = "N", dx = 1, dy = 1 },
        { key = "shift+left", dx = -1, dy = 0 },
        { key = "shift+right", dx = 1, dy = 0 },
        { key = "shift+up", dx = 0, dy = -1 },
        { key = "shift+down", dx = 0, dy = 1 },
        { key = "shift+home", dx = -1, dy = -1 },
        { key = "shift+pgup", dx = 1, dy = -1 },
        { key = "shift+end", dx = -1, dy = 1 },
        { key = "shift+pgdown", dx = 1, dy = 1 },
    }

    for _, binding in ipairs(bindings) do
        local routed = play.route({ key = binding.key })

        harness.equal(routed.action, modes.ACTION)
        harness.equal(routed.mode, modes.RUN)
        harness.equal(routed.dx, binding.dx)
        harness.equal(routed.dy, binding.dy)
    end

    harness.equal(play.route({ key = "5" }).mode, modes.REST)
    harness.equal(play.route({ key = "o" }).mode, modes.EXPLORE)
end

-- A run records forward and flank feature classes before the first move.
-- A changed flank, visible foe, cloud, or wall stops before another step.
local function run_interrupts()
    local view = open_view()
    local state = automation.start({
        mode = modes.RUN,
        dx = 1,
        dy = 0,
        view = view,
    })

    harness.equal(automation.next({ state = state, view = view }).kind,
        commands.move)

    cell(view, 4, 2).feature = features.DNGN_OPEN_DOOR
    harness.equal(automation.next({ state = state, view = view }).action,
        modes.STOP)

    cell(view, 4, 2).feature = features.DNGN_FLOOR
    view.entities = {
        { role = "monster", hostile = true },
    }
    harness.equal(automation.next({ state = state, view = view }).action,
        modes.STOP)

    view.entities = {}
    view.clouds = {
        { x = 4, y = 3 },
    }
    harness.equal(automation.next({ state = state, view = view }).action,
        modes.STOP)

    view.clouds = {}
    cell(view, 4, 3).walkable = false
    harness.equal(automation.next({ state = state, view = view }).action,
        modes.STOP)

    -- Diagonal travel notices a door passing on either perpendicular
    -- side, even when the three usual forward cells are unchanged.
    local diagonal = automation.start({
        mode = modes.RUN,
        dx = 1,
        dy = -1,
        view = open_view(),
    })
    local diagonal_view = open_view()

    cell(diagonal_view, 4, 4).feature = features.DNGN_CLOSED_DOOR
    harness.equal(automation.next({
        state = diagonal,
        view = diagonal_view,
    }).action, modes.STOP)
end

-- `5` rests while recovery can help. At full resources it becomes the
-- source's 100-turn wait, which does not finish after its first tick.
local function rest_and_wait()
    local view = open_view()

    view.hp = 8

    local resting = automation.start({ mode = modes.REST, view = view })

    harness.equal(resting.mode, modes.REST)
    harness.equal(automation.next({ state = resting, view = view }).kind,
        commands.wait)

    view.hp = view.max_hp
    harness.equal(automation.next({ state = resting, view = view }).action,
        modes.STOP)

    local waiting = automation.start({ mode = modes.REST, view = view })

    harness.equal(waiting.mode, modes.WAIT)
    harness.equal(waiting.remaining, 100)
    harness.equal(automation.next({ state = waiting, view = view }).kind,
        commands.wait)

    -- The key switches to a finite wait if neither depleted pool can
    -- improve while stationary, as with no-regeneration characters.
    view.hp = 8
    view.can_recover_hp = false

    local unable = automation.start({ mode = modes.REST, view = view })

    harness.equal(unable.mode, modes.WAIT)
end

-- Explore chooses a reachable frontier in a stable order and refuses to
-- route through known walls or through an already visible hostile actor.
local function explore_frontier()
    local view = open_view()

    for y = 0, 6 do
        for x = 5, 6 do
            cell(view, x, y).state = 0
            cell(view, x, y).feature = ""
            cell(view, x, y).walkable = false
        end
    end

    local state = automation.start({ mode = modes.EXPLORE,
        view = view })
    local first = automation.next({ state = state, view = view })

    harness.equal(first.kind, commands.move)
    harness.truthy(first.dx > 0,
        "explore did not approach the only unknown region")

    -- At a known frontier, do not blindly step onto a tile whose
    -- terrain remains hidden. Another known frontier may remain.
    view.player_x = 4
    local second = automation.next({ state = first.state,
        view = view })
    local destination = cell(view, view.player_x + second.dx,
        view.player_y + second.dy)

    harness.equal(second.kind, commands.move)
    harness.truthy(destination.state > 0,
        "explore attempted to enter unseen terrain")

    view.entities = {
        { role = "monster", hostile = true },
    }
    harness.equal(automation.next({ state = state, view = view }).action,
        modes.STOP)
end

-- A frontier already reached without revealing its neighboring cells is
-- exhausted. The same route then continues toward another frontier.
local function explore_other_frontier()
    local view = open_view()

    for _, observed in ipairs(view.cells) do
        observed.walkable = false
    end

    for x = 1, 4 do
        cell(view, x, 3).walkable = true
    end

    cell(view, 5, 3).state = 0
    cell(view, 5, 3).feature = ""
    cell(view, 5, 3).walkable = false
    cell(view, 0, 3).state = 0
    cell(view, 0, 3).feature = ""
    cell(view, 0, 3).walkable = false
    view.player_x = 4

    local state = automation.start({ mode = modes.EXPLORE,
        view = view })
    local next_step = automation.next({ state = state, view = view })

    harness.equal(next_step.kind, commands.move)
    harness.truthy(next_step.dx < 0,
        "explore did not leave an exhausted frontier")

    -- When this is the only reachable observation point, stop safely
    -- rather than guessing that its unseen neighbor is traversable.
    cell(view, 0, 3).state = 2
    cell(view, 0, 3).feature = features.DNGN_ROCK_WALL

    local exhausted = automation.next({
        state = next_step.state,
        view = view,
    })

    harness.equal(exhausted.action, modes.STOP)
end

-- Friendly actors and clouds cannot become path cells. Deep water and
-- lava require the player's live movement capabilities, not grid walkable.
local function explore_avoids_obstacles()
    local view = open_view()

    for _, observed in ipairs(view.cells) do
        observed.walkable = false
    end

    cell(view, 3, 3).walkable = true
    cell(view, 4, 3).walkable = true
    cell(view, 5, 3).state = 0

    local state = automation.start({ mode = modes.EXPLORE,
        view = view })

    view.entities = {
        { x = 4, y = 3, role = "monster", hostile = false },
    }
    harness.equal(automation.next({ state = state,
        view = view }).action, modes.STOP)

    view.entities = {}
    view.clouds = { { x = 4, y = 3 } }
    harness.equal(automation.next({ state = state,
        view = view }).action, modes.STOP)

    view.clouds = {}
    cell(view, 4, 3).feature = features.DNGN_LAVA
    harness.equal(automation.next({ state = state,
        view = view }).action, modes.STOP)

    view.can_cross_lava = true
    harness.equal(automation.next({ state = state,
        view = view }).kind, commands.move)

    cell(view, 4, 3).feature = features.DNGN_DEEP_WATER
    harness.equal(automation.next({ state = state,
        view = view }).action, modes.STOP)

    view.can_cross_deep_water = true
    harness.equal(automation.next({ state = state,
        view = view }).kind, commands.move)
end

-- Every check calls the production owner and shared identifiers.
function test.run()
    source_keys()
    run_interrupts()
    rest_and_wait()
    explore_frontier()
    explore_other_frontier()
    explore_avoids_obstacles()
end

return test
