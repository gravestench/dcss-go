-- Exercise the real region bridge through a sparse mod policy. The
-- neutral Abyss storage is the test surface so no Dungeon stair link
-- or monster population affects the transaction assertions.
local constants = require("constants.abyss")
local terrain = require("constants.terrain")
local abyss_world = require("policy.world.abyss")
local abyss_exits = require("policy.world.abyss.exits")
local player_teleport = require("policy.magic.player_teleport")
local catalog = require("policy.catalog")
local component = require("constants.component")

local test = {}

-- A mod copies the existing typed grid into a complete candidate plan.
-- The host validates that plan before publishing any of its fields.
local function region_plan(ctx, level_id)
    local width, height = ctx:level_size(level_id)
    local cells = {}

    for y = 0, height - 1 do
        local row = {}

        for x = 0, width - 1 do
            row[x + 1] = ctx:cell(level_id, x, y)
        end

        cells[y + 1] = row
    end

    return {
        cells = cells,
        local_depth = ctx:level_depth(level_id),
        stairs = {},
        vault_records = {},
        actor_moves = {},
    }
end

-- Change one cell in the neutral Abyss storage for terrain tests.
local function replacement(ctx)
    local plan = region_plan(ctx, constants.LEVEL_ID)

    plan.cells[3][3] = terrain.DNGN_ROCK_WALL

    return plan
end

-- Search a real Dungeon floor for an unoccupied landing, so the Lua
-- bridge tests actor handles and the host's simultaneous move validator.
local function free_landing(ctx, level_id, original)
    local width, height = ctx:level_size(level_id)

    for y = 1, height - 2 do
        for x = 1, width - 2 do
            if (x ~= original.x or y ~= original.y) and
                ctx:walkable(level_id, x, y) and
                not ctx:actor_at(level_id, x, y) then
                return x, y
            end
        end
    end

    error("test floor has no free landing")
end

-- The pending Lua view should see the new cell before the Go action
-- barrier publishes it to the game-owned level.
function test.stage(ctx)
    ctx:replace_region(constants.LEVEL_ID, replacement(ctx))

    if ctx:cell(constants.LEVEL_ID, 2, 2) ~=
        terrain.DNGN_ROCK_WALL then
        error("pending region cell was not visible to Lua")
    end

    return {}
end

-- A later hook failure must discard the staged replacement, including
-- its pending view, without touching the saved live level.
function test.fail(ctx)
    ctx:random("region-test", 99)
    ctx:random_u64("region-test-word")
    ctx:replace_region(constants.LEVEL_ID, replacement(ctx))
    error("forced region failure")
end

-- A successful decision can draw randomness without staging a command.
-- That draw must survive the next action's pending-command cleanup.
function test.rng_only(ctx)
    return {
        draw = ctx:random("region-read-only", 99),
    }
end

-- A region transaction presents a moved actor through ctx:get before
-- commit, while the game-owned position changes only at ApplyPending.
function test.move_player(ctx)
    local player = ctx:player()
    local old = ctx:get(player, "core.position")
    local x, y = free_landing(ctx, old.level_id, old)
    local plan = region_plan(ctx, old.level_id)

    plan.actor_moves = {
        {
            actor = player,
            level_id = old.level_id,
            x = x,
            y = y,
        },
    }

    ctx:replace_region(old.level_id, plan)

    local pending = ctx:get(player, "core.position")

    if pending.x ~= x or pending.y ~= y then
        error("pending actor position does not match region move")
    end

    return {
        x = x,
        y = y,
    }
end

-- Reading and replacing a complete region without edits must preserve
-- every saved field. Shift policy will transform this same detached plan.
function test.roundtrip(ctx)
    local plan = ctx:region_plan(constants.LEVEL_ID)

    ctx:replace_region(constants.LEVEL_ID, plan)

    return {}
end

-- Session state is saved beside the mutable level. Lua creates the
-- record through a generic transaction, not a Go branch policy switch.
local function candidate_abyss_state()
    local floor = terrain.DNGN_FLOOR

    return {
        branch_depth = 1,
        morph_depth = 4,
        phase = 0,
        world_x = 1,
        world_y = 2,
        terrain_seed = 3,
        shift_count = 0,
        borrowed_level_id = 1,
        borrowed_layout = {
            { floor, floor, floor },
            { floor, floor, floor },
            { floor, floor, floor },
        },
        sample_queue = {},
        exit_xp = 10,
        exit_spawned = false,
        min_branch_depth = 1,
        pocket_start = false,
        selected_map_ids = {},
        transit = {},
    }
end

-- Reading within one action sees the staged record, while Go still owns
-- the old snapshot until the same ApplyPending barrier as region changes.
function test.session_stage(ctx)
    if ctx:session_state("abyss") then
        error("test expected no active Abyss state")
    end

    ctx:replace_session_state("abyss", candidate_abyss_state())

    if ctx:session_state("abyss").world_x ~= 1 then
        error("staged Abyss state was not readable")
    end

    return {}
end

-- A failed policy after a state change must not publish the new state.
function test.session_fail(ctx)
    local state = ctx:session_state("abyss")

    state.world_x = 99
    ctx:replace_session_state("abyss", state)
    error("forced session state failure")
end

-- Enter through the production world policy, proving first entry chooses
-- a borrowed floor and publishes its generated window with the player.
function test.enter_abyss(ctx)
    abyss_world.banish(ctx, ctx:player())

    return {}
end

-- Banish a real fixed-scenario monster before the player visits the Abyss.
-- Its ECS identity must survive the first generated window and a save.
function test.banish_monster(ctx)
    for _, actor in ipairs(ctx:query({
        component.AI,
        component.POSITION,
    })) do
        local position = ctx:get(actor, component.POSITION)

        if position.level_id == 1 then
            local kind = ctx:get(actor, component.ACTOR).kind_id

            abyss_world.banish_monster(ctx, actor,
                catalog.get("monsters", kind))

            return { entity_id = ctx:id(actor) }
        end
    end

    error("test has no D:1 monster to banish")
end

-- Drive the production XP rule through a real game context. A large
-- credited reward makes the first gate deterministic at every level.
function test.abyss_xp_exit(ctx)
    abyss_exits.award(ctx, ctx:player(), 100000)

    return {}
end

-- The player teleport rule calls this same fresh-region policy when the
-- active floor is Abyss rather than choosing a coordinate on the old map.
function test.abyss_teleport(ctx)
    player_teleport.now(ctx, ctx:player())

    return {}
end

register.policy({
    id = "test.region_stage",
    run = test.stage,
})

register.policy({
    id = "test.region_fail",
    run = test.fail,
})

register.policy({
    id = "test.region_rng_only",
    run = test.rng_only,
})

register.policy({
    id = "test.region_move_player",
    run = test.move_player,
})

register.policy({
    id = "test.region_roundtrip",
    run = test.roundtrip,
})

register.policy({
    id = "test.region_session_stage",
    run = test.session_stage,
})

register.policy({
    id = "test.region_session_fail",
    run = test.session_fail,
})

register.policy({
    id = "test.region_enter_abyss",
    run = test.enter_abyss,
})

register.policy({
    id = "test.abyss_banish_monster",
    run = test.banish_monster,
})

register.policy({
    id = "test.abyss_xp_exit",
    run = test.abyss_xp_exit,
})

register.policy({
    id = "test.abyss_teleport",
    run = test.abyss_teleport,
})

return test
