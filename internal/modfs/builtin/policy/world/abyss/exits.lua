-- Theory of operation: time and distance can reveal sparse Abyss exits,
-- but credited monster XP owns a separate source clock. The clock uses
-- the player's level and branch depth so killing weak monsters deep in
-- the Abyss rarely opens a gate. Once earned, the gate appears under the
-- player on a safe ordinary floor cell and the clock resets.
local abyss = require("constants.abyss")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local exits = {}

-- The source scales one gateway step by the next human level threshold,
-- the current level, and the extra penalty at Abyss:6 and below.
local function xp_factor(level, depth)
    local next_level_xp = formulas.experience_needed(level + 1, 0)
    local base = math.max(math.min(
        math.floor(next_level_xp / 7), level * 425),
        level * 2 + 15)

    return math.max(1, math.floor(base / 5)) *
        math.max(1, depth - 4)
end

-- div_rand_round spends one draw only for a remainder. This keeps small
-- kills probabilistic without biasing the expected source XP progress.
local function rounded_share(ctx, xp, factor)
    local whole = math.floor(xp / factor)
    local remainder = xp % factor

    if remainder > 0 and
        ctx:random(streams.POPULATION_COUNT, factor) < remainder then
        whole = whole + 1
    end

    return whole
end

-- A credited, nonsummoned kill calls this after ordinary player XP is
-- awarded. The state update and terrain change share the action barrier.
function exits.award(ctx, player, xp)
    local position = ctx:get(player, component.POSITION)

    if not position or position.level_id ~= abyss.LEVEL_ID or xp <= 0 then
        return
    end

    local state = ctx:session_state(abyss.SESSION_STATE)
    local progress = ctx:get(player, component.PROGRESSION)

    if not state or not progress then
        error("Abyss XP exit lacks procedural or player state")
    end

    state.exit_xp = math.max(0, state.exit_xp -
        rounded_share(ctx, xp,
            xp_factor(progress.level, state.branch_depth)))

    -- A stair, portal, or another authored feature underfoot has its own
    -- travel rule. Retain the earned gate until ordinary floor is reached.
    if state.exit_xp == 0 and
        ctx:cell(abyss.LEVEL_ID, position.x,
            position.y) == terrain.DNGN_FLOOR then
        local bottom = catalog.get(categories.BRANCHES,
            branches.BRANCH_ABYSS).depth
        local stair = state.exit_spawned and
            state.branch_depth < bottom and
            ctx:random(streams.POPULATION_COUNT, 2) == 0
        local feature = stair and terrain.DNGN_ABYSSAL_STAIR or
            terrain.DNGN_EXIT_ABYSS

        ctx:set_cell(abyss.LEVEL_ID, position.x, position.y, feature)
        state.exit_xp = abyss.EXIT_XP_COST
        state.exit_spawned = true
        ctx:emit("banishment", "The substance of the Abyss twists " ..
            "violently, and a gateway leading " ..
            (stair and "down" or "out") .. " appears!")
    end

    ctx:replace_session_state(abyss.SESSION_STATE, state)
end

return exits
