-- Theory of operation: source automatic commands repeat ordinary player
-- actions. Lua reads the player's observed map, chooses one command, and
-- stops before a newly dangerous or surprising move. The terminal timer
-- only schedules these decisions; Game.Step owns every resulting turn.
local commands = require("policy.input.commands")
local features = require("constants.terrain")
local modes = require("constants.automation")
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local mutation_effects = require("policy.mutations.effects.registry")
local regeneration = require("policy.character.regeneration")
local statuses = require("policy.magic.effects.statuses.player")

local automation = {}

-- Clockwise source compass order also fixes BFS ties for autoexplore.
local compass = {
    { dx = 0, dy = -1 },
    { dx = 1, dy = -1 },
    { dx = 1, dy = 0 },
    { dx = 1, dy = 1 },
    { dx = 0, dy = 1 },
    { dx = -1, dy = 1 },
    { dx = -1, dy = 0 },
    { dx = -1, dy = -1 },
}

local run_keys = {
    K = 1,
    U = 2,
    L = 3,
    N = 4,
    J = 5,
    B = 6,
    H = 7,
    Y = 8,
    ["shift+up"] = 1,
    ["shift+pgup"] = 2,
    ["shift+right"] = 3,
    ["shift+pgdown"] = 4,
    ["shift+down"] = 5,
    ["shift+end"] = 6,
    ["shift+left"] = 7,
    ["shift+home"] = 8,
}

-- Source `_base_feat_type` treats wall materials as one feature class.
-- Doors, stairs, water, and other meaningful changes keep their own IDs.
local walls = {
    [features.DNGN_ROCK_WALL] = true,
    [features.DNGN_STONE_WALL] = true,
    [features.DNGN_CLEAR_PERMAROCK_WALL] = true,
    [features.DNGN_CLEAR_ROCK_WALL] = true,
    [features.DNGN_CLEAR_STONE_WALL] = true,
    [features.DNGN_CRYSTAL_WALL] = true,
    [features.DNGN_METAL_WALL] = true,
    [features.DNGN_PERMAROCK_WALL] = true,
    [features.DNGN_SLIMY_WALL] = true,
}

local doors = {
    [features.DNGN_OPEN_DOOR] = true,
    [features.DNGN_CLOSED_DOOR] = true,
    [features.DNGN_OPEN_CLEAR_DOOR] = true,
    [features.DNGN_CLOSED_CLEAR_DOOR] = true,
    [features.DNGN_SEALED_DOOR] = true,
    [features.DNGN_SEALED_CLEAR_DOOR] = true,
}

-- The terminal asks this owner to classify source key bindings. Plain
-- movement remains in directions.lua and spends only one ordinary action.
function automation.key(key)
    local direction = run_keys[key]

    if direction then
        return {
            action = modes.ACTION,
            mode = modes.RUN,
            dx = compass[direction].dx,
            dy = compass[direction].dy,
        }
    end

    if key == "5" then
        return {
            action = modes.ACTION,
            mode = modes.REST,
        }
    end

    if key == "o" then
        return {
            action = modes.ACTION,
            mode = modes.EXPLORE,
        }
    end

    return nil
end

-- Rest only waits for pools that the current character can recover by
-- waiting. This matches the source's `is_sufficiently_rested` gate and
-- prevents an endless rest for no-regeneration or explore-healing forms.
function automation.rest_capabilities(ctx)
    local player = ctx:player()
    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    if not health or not magic then
        error("rest requires live player resources")
    end

    if mutation_effects.sum(ctx, player,
        capabilities.EXPLORE_REGEN) > 0 then
        return {
            hp = false,
            mp = false,
        }
    end

    local hp_rate, mp_rate = regeneration.rates(ctx, player,
        health.max, magic.max)

    return {
        hp = statuses.hp_regen_allowed(ctx, player) and
            regeneration.effective_hp_rate(ctx, player, hp_rate) > 0,
        mp = mp_rate > 0,
    }
end

-- Unknown cells have no feature ID and must never reveal live terrain to
-- the automation policy. The host supplies only remembered and seen cells.
local function cell(view, x, y)
    if x < 0 or y < 0 or x >= view.width or y >= view.height then
        return nil
    end

    return view.cells[y * view.width + x + 1]
end

-- A wall material change should not stop a run; a door or new stair should.
local function feature_class(observed)
    if not observed or observed.state == 0 then
        return ""
    end

    if walls[observed.feature] then
        return features.DNGN_ROCK_WALL
    end

    return observed.feature
end

-- Find the source forward and two flanking checks for a run direction.
-- Store their original classes so later turns can spot a new junction.
local function run_checks(view, dx, dy)
    local index

    for position, direction in ipairs(compass) do
        if direction.dx == dx and direction.dy == dy then
            index = position
            break
        end
    end

    if not index then
        error("invalid automatic run direction")
    end

    local checks = {}

    for offset = -1, 1 do
        local neighbor = compass[(index + offset - 1) % #compass + 1]
        local observed = cell(view, view.player_x + neighbor.dx,
            view.player_y + neighbor.dy)

        checks[#checks + 1] = feature_class(observed)
    end

    return checks
end

-- Long rest follows source `is_sufficiently_rested`: at full resources
-- the same key waits one hundred turns; otherwise it rests until recovered.
function automation.start(input)
    local mode = input.mode
    local view = input.view

    if mode == modes.RUN then
        return {
            mode = modes.RUN,
            dx = input.dx,
            dy = input.dy,
            checks = run_checks(view, input.dx, input.dy),
        }
    end

    if mode == modes.REST then
        local depleted = (view.can_recover_hp and view.hp < view.max_hp) or
            (view.can_recover_mp and view.mp < view.max_mp)

        return {
            mode = depleted and modes.REST or modes.WAIT,
            remaining = depleted and 0 or 100,
        }
    end

    if mode == modes.EXPLORE then
        return { mode = modes.EXPLORE }
    end

    error("unknown automatic movement mode " .. tostring(mode))
end

-- Source travel stops when a hostile becomes visible. The view has already
-- withheld monsters that the player cannot perceive.
local function visible_threat(view)
    for _, entity in ipairs(view.entities or {}) do
        if entity.role == "monster" and entity.hostile then
            return true
        end
    end

    return false
end

-- A repeated run does not attack occupants or enter source clouds.
local function occupied_or_cloudy(view, x, y)
    for _, entity in ipairs(view.entities or {}) do
        if entity.x == x and entity.y == y and
            entity.role ~= "player" then
            return true
        end
    end

    for _, cloud in ipairs(view.clouds or {}) do
        if cloud.x == x and cloud.y == y then
            return true
        end
    end

    return false
end

-- A diagonal run can pass a door beside the route without seeing it in
-- the ordinary forward/flank checks. Source travel inspects the two
-- perpendicular cells separately for this reason.
local function diagonal_passes_door(state, view)
    if state.dx == 0 or state.dy == 0 then
        return false
    end

    local left = cell(view, view.player_x - state.dy,
        view.player_y + state.dx)
    local right = cell(view, view.player_x + state.dy,
        view.player_y - state.dx)

    return left and doors[left.feature] or right and doors[right.feature]
end

-- One run step is permitted only when the old three-feature corridor
-- pattern still holds and the next known cell admits ordinary movement.
local function next_run(state, view)
    local x = view.player_x + state.dx
    local y = view.player_y + state.dy
    local target = cell(view, x, y)

    if not target or not target.walkable or
        diagonal_passes_door(state, view) or
        occupied_or_cloudy(view, x, y) then
        return { action = modes.STOP }
    end

    local checks = run_checks(view, state.dx, state.dy)

    for index, original in ipairs(state.checks) do
        if checks[index] ~= original then
            return { action = modes.STOP }
        end
    end

    return {
        action = "step",
        kind = commands.move,
        dx = state.dx,
        dy = state.dy,
    }
end

-- The source's long wait counts down even at full health. Actual resting
-- stops once both pools have recovered; an input key can interrupt either.
local function next_rest(state, view)
    if state.mode == modes.WAIT and state.remaining <= 0 then
        return { action = modes.STOP }
    end

    if state.mode == modes.REST and
        (not view.can_recover_hp or view.hp >= view.max_hp) and
        (not view.can_recover_mp or view.mp >= view.max_mp) then
        return { action = modes.STOP }
    end

    return {
        action = "step",
        kind = commands.wait,
    }
end

-- Explore paths through remembered walkable cells toward the nearest
-- frontier. Unknown terrain is tried only when standing at that frontier;
-- a failed ordinary move then ends automation without spending a turn.
local function next_explore(view)
    local queue = {
        {
            x = view.player_x,
            y = view.player_y,
        },
    }
    local seen = {
        [view.player_x .. ":" .. view.player_y] = true,
    }
    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        for _, direction in ipairs(compass) do
            local x = point.x + direction.dx
            local y = point.y + direction.dy
            local neighbor = cell(view, x, y)

            if neighbor and neighbor.state == 0 then
                local first = point.first or direction

                return {
                    action = "step",
                    kind = commands.move,
                    dx = first.dx,
                    dy = first.dy,
                }
            end
        end

        for _, direction in ipairs(compass) do
            local x = point.x + direction.dx
            local y = point.y + direction.dy
            local key = x .. ":" .. y
            local neighbor = cell(view, x, y)

            if neighbor and neighbor.state > 0 and
                neighbor.walkable and not seen[key] then
                seen[key] = true
                queue[#queue + 1] = {
                    x = x,
                    y = y,
                    first = point.first or direction,
                }
            end
        end
    end

    return { action = modes.STOP }
end

-- One public decision serves every automatic intent. The host never
-- substitutes an alternative command after Lua asks to stop.
function automation.next(input)
    local state = input.state
    local view = input.view

    if visible_threat(view) then
        return { action = modes.STOP }
    end

    if state.mode == modes.RUN then
        return next_run(state, view)
    end

    if state.mode == modes.REST or state.mode == modes.WAIT then
        return next_rest(state, view)
    end

    if state.mode == modes.EXPLORE then
        return next_explore(view)
    end

    error("unknown active automation mode " .. tostring(state.mode))
end

-- The terminal uses one registered read-only policy at both boundaries.
function automation.run(_, input)
    if input.phase == "start" then
        return automation.start(input)
    end

    if input.phase == "next" then
        return automation.next(input)
    end

    error("unknown automatic movement phase " .. tostring(input.phase))
end

register.policy({
    id = "terminal.automation",
    run = automation.run,
})

register.policy({
    id = "presentation.rest_capabilities",
    run = automation.rest_capabilities,
})

return automation
