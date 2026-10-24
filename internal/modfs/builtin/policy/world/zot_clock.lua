local branches = require("ids.branches")
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local constants = require("constants.zot_clock")
local catalog = require("policy.catalog")
local effects = require("policy.mutations.effects.registry")
local extra_lives = require("policy.character.extra_lives")
local player_drain = require("policy.combat.player_drain")

local zot = {}

-- Mutation strength divides the floor credit and scales warning thresholds together.
local function divisor(ctx, player)
    return 1 + effects.sum(ctx, player,
        capabilities.ZOT_CLOCK_EXTRA_DIVISOR)
end

-- Pair branch and level so returning to a visited floor gives no second clock credit.
local function floor_key(branch_id, floor_id)
    return branch_id .. ":" .. floor_id
end

-- Translate remaining branch time into warning tiers before the fatal boundary.
local function warning_for(value, scale)
    if value < 0 then
        return 0
    end

    local remaining = math.floor((constants.MAX_AUT - value) /
        constants.AUT_PER_TURN) * scale

    if remaining < 100 then
        return 3
    end

    if remaining < 500 then
        return 2
    end

    if remaining < 1000 then
        return 1
    end

    return 0
end

-- Severe drain turns Zot's next touch lethal once maximum HP is at most a tenth of its undrained value.
local function fatal_range(ctx, player)
    local health = ctx:get(player, component.HEALTH)
    local drain = ctx:get(player, component.PLAYER_DRAIN)

    if not health or not drain or drain.amount <= 0 then
        return false
    end

    local real_max = health.max + drain.amount

    return health.max <= math.floor(real_max / 10)
end

-- Warnings mention death only when existing drain makes the next touch fatal.
local function warning_message(level, fatal)
    local consequence = fatal and "perish" or "suffer"

    if level == 1 then
        return "You have lingered too long. Zot senses you. " ..
            "Dive deeper or flee this branch before you " .. consequence .. "!"
    end

    if level == 2 then
        return "Zot draws nearer. Dive deeper or flee this branch before you " ..
            consequence .. "!"
    end

    local ending = fatal and "Death" or "Suffering"

    return "Zot has nearly found you. " .. ending ..
        " is approaching. Descend or flee this branch!"
end

-- Zot's touch resets branch time after draining; a fatal threshold consumes the remaining branch clock.
local function touch(ctx, player, state, branch_id, scale)
    if fatal_range(ctx, player) then
        local health = ctx:get(player, component.HEALTH)

        ctx:emit("warning", "Zot finds you!")

        state.branch_aut[branch_id] = constants.MAX_AUT
        health.current = 0
        ctx:set(player, component.HEALTH, health)
        extra_lives.on_lethal(ctx, player)

        return true
    end

    ctx:emit("warning", "Zot's power touches on you...")
    player_drain.apply(ctx, player, constants.DRAIN_POWER,
        constants.RNG_STREAM)

    local turns = constants.ORDINARY_RESET_TURNS

    if scale > 1 then
        turns = constants.SHORT_RESET_TURNS
    end

    state.branch_aut[branch_id] = constants.MAX_AUT -
        turns * constants.AUT_PER_TURN

    return false
end

-- A saved branch clock must own at least one visited floor and belong only to the player.
function zot.validate(ctx, player)
    local state = ctx:get(player, component.ZOT_CLOCK)

    if not state then
        error("player has no Zot clock")
    end

    local branch_has_floor = {}

    for branch_id, value in pairs(state.branch_aut) do
        catalog.get("branches", branch_id)

        if type(value) ~= "number" or value < 0 or
            value > constants.MAX_AUT or value % 1 ~= 0 then
            error("invalid Zot clock for branch " .. branch_id)
        end

        branch_has_floor[branch_id] = false
    end

    for key, visited in pairs(state.visited_floors) do
        local branch_id, floor_id = key:match("^([^:]+):([1-9][0-9]*)$")

        if visited ~= true or not branch_id or not floor_id or
            branch_has_floor[branch_id] == nil then
            error("invalid visited Zot floor " .. key)
        end

        branch_has_floor[branch_id] = true
    end

    for branch_id, has_floor in pairs(branch_has_floor) do
        if not has_floor then
            error("Zot branch has no visited floor " .. branch_id)
        end
    end

    for _, entity in ipairs(ctx:query({ component.ZOT_CLOCK })) do
        if entity ~= player then
            error("Zot clock belongs to a non-player entity")
        end
    end

    local position = ctx:get(player, component.POSITION)

    if position then
        local branch_id = ctx:level_branch(position.level_id)

        if not branch_id then
            error("player is on a level with no branch")
        end

        if branch_id == branches.BRANCH_ABYSS then
            return
        end

        local key = floor_key(branch_id, position.level_id)

        if not state.visited_floors[key] then
            error("current floor is absent from Zot clock")
        end
    end
end

-- Return the branch's saved elapsed aut, or -1 until the player has visited that branch.
-- Example: zot.clock(ctx, player, branches.BRANCH_DUNGEON) reads elapsed branch aut or -1 before the first visit.
function zot.clock(ctx, player, branch_id)
    local state = ctx:get(player, component.ZOT_CLOCK)

    if not state then
        return -1
    end

    return state.branch_aut[branch_id] or -1
end

-- Use the same divisor as advance so UI warnings match future branch spending.
function zot.warning_level(ctx, player, branch_id)
    return warning_for(zot.clock(ctx, player, branch_id),
        divisor(ctx, player))
end

-- zot.cc: entering a new floor restores branch time before the
-- action spends aut. Re-entering a visited floor grants no additional time.
function zot.advance(ctx, player, branch_id, floor_id, elapsed_aut)
    if type(branch_id) ~= "string" or branch_id == "" or
        type(floor_id) ~= "number" or floor_id < 1 or
        floor_id % 1 ~= 0 or type(elapsed_aut) ~= "number" or
        elapsed_aut < 0 or elapsed_aut % 1 ~= 0 then
        error("invalid Zot clock advance")
    end

    catalog.get("branches", branch_id)

    local state = ctx:get(player, component.ZOT_CLOCK)
    local existed = state ~= nil

    if not existed then
        state = {
            branch_aut = {},
            visited_floors = {},
        }
    end

    local old_value = state.branch_aut[branch_id] or -1
    local scale = divisor(ctx, player)
    local old_warning = warning_for(old_value, scale)
    local key = floor_key(branch_id, floor_id)

    if not state.visited_floors[key] then
        if old_value < 0 then
            old_value = constants.MAX_AUT
        end

        old_value = math.max(0,
            old_value - constants.FLOOR_AUT / scale)
        state.visited_floors[key] = true
    end

    state.branch_aut[branch_id] = old_value + elapsed_aut

    local fatal = false

    if state.branch_aut[branch_id] >= constants.MAX_AUT then
        fatal = touch(ctx, player, state, branch_id, scale)
    end

    if existed then
        ctx:set(player, component.ZOT_CLOCK, state)
    else
        ctx:add(player, component.ZOT_CLOCK, state)
    end

    if fatal then
        return
    end

    local new_warning = warning_for(state.branch_aut[branch_id], scale)

    if new_warning > old_warning then
        ctx:emit("warning", warning_message(new_warning,
            fatal_range(ctx, player)))
    end
end

-- The Abyss does not charge branch time; other actions advance the active branch clock.
function zot.run(ctx, input)
    if input.branch_id == branches.BRANCH_ABYSS then
        return {}
    end

    zot.advance(ctx, ctx:player(), input.branch_id,
        input.level_id, input.elapsed_aut)

    return {}
end

register.policy({
    id = "world.zot_clock",
    run = zot.run,
})

return zot
