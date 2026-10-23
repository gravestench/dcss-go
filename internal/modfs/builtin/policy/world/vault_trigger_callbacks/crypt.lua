-- Theory of operation: Crypt's two source marker groups change terrain
-- only when their saved trigger entity fires. The group stores oriented
-- target cells on the ECS trigger, so no map-global Lua table is needed.
local channels = require("constants.message_channels")
local colours = require("constants.vault_colours")
local component = require("constants.component")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local factory = require("policy.population.factory")
local silence = require("policy.world.silence")

local crypt = {}

local guard_choices = {
    {
        kind_id = monsters.MONS_SKELETON,
        base_id = monsters.MONS_HUMAN,
        weight = 10,
    },
    {
        kind_id = monsters.MONS_ZOMBIE,
        base_id = monsters.MONS_HUMAN,
        weight = 10,
    },
    {
        kind_id = monsters.MONS_MUMMY,
        weight = 20,
    },
    {
        kind_id = monsters.MONS_GUARDIAN_MUMMY,
        weight = 10,
    },
}

-- Reject a broken marker group before making any irreversible cell change.
-- All coordinates come from the final oriented DES record set.
local function validate_group(state)
    if
        #state.wall_x == 0
        or #state.wall_x ~= #state.wall_y
        or #state.wall_x ~= #state.wall_record_indices
    then
        error("Crypt trigger has no complete target group")
    end
end

-- Source crypt_drop_grates checks visibility only to choose its message;
-- every remaining grate falls even when it is outside the player's view.
local function grates_drop(ctx, state)
    validate_group(state)

    local player = ctx:get(ctx:player(), component.POSITION)
    local saw_change = false

    for index, x in ipairs(state.wall_x) do
        local y = state.wall_y[index]
        local feature = ctx:cell(state.level_id, x, y)

        if feature ~= terrain.DNGN_GRATE and feature ~= terrain.DNGN_FLOOR then
            error("Crypt grate changed before its trigger fired")
        end

        if
            feature == terrain.DNGN_GRATE
            and player
            and player.level_id == state.level_id
            and ctx:visible(state.level_id, player.x, player.y, 7, x, y)
        then
            saw_change = true
        end
    end

    for index, x in ipairs(state.wall_x) do
        local y = state.wall_y[index]

        if ctx:cell(state.level_id, x, y) == terrain.DNGN_GRATE then
            ctx:set_cell(state.level_id, x, y, terrain.DNGN_FLOOR)
        end
    end

    if saw_change then
        ctx:emit(
            channels.WARNING,
            "There is a click. Suddenly, the grates are dropped!"
        )
    else
        ctx:emit(
            channels.WARNING,
            "There is a click. Nothing appears to happen."
        )
    end
end

-- Draw one of the source alternatives for each sealed occupant. The
-- selected base species remains attached to a generic zombie or skeleton.
local function guard_choice(ctx)
    local pick = ctx:random(streams.PLACEMENT, 50)

    for _, choice in ipairs(guard_choices) do
        if pick < choice.weight then
            return choice
        end

        pick = pick - choice.weight
    end

    error("Crypt guard draw exceeded its source alternatives")
end

-- Prefer the visible awakening line. Otherwise source Crawl distinguishes
-- magical silence from an ordinary audible grinding-stone warning.
local function guard_message(ctx, state, player)
    if player and player.level_id == state.level_id then
        for index, x in ipairs(state.wall_x) do
            if
                ctx:visible(
                    state.level_id,
                    player.x,
                    player.y,
                    7,
                    x,
                    state.wall_y[index]
                )
            then
                return "Something awakens from inside the sarcophagi!"
            end
        end

        if silence.at(ctx, state.level_id, player.x, player.y) then
            return "The ground shakes!"
        end
    end

    return "You hear grinding stone!"
end

-- Source callback.grunt_crypt_arrival_guards_awaken opens every surviving
-- granite sarcophagus and creates an awake undead guard on its former cell.
local function guards_awaken(ctx, state)
    validate_group(state)

    for index, x in ipairs(state.wall_x) do
        local feature = ctx:cell(state.level_id, x, state.wall_y[index])

        if
            feature ~= terrain.DNGN_GRANITE_STATUE
            and feature ~= terrain.DNGN_FLOOR
        then
            error("Crypt sarcophagus changed before its trigger fired")
        end
    end

    local player = ctx:get(ctx:player(), component.POSITION)
    local message = guard_message(ctx, state, player)

    ctx:emit(channels.WARNING, message)

    for index, x in ipairs(state.wall_x) do
        local y = state.wall_y[index]

        if ctx:cell(state.level_id, x, y) == terrain.DNGN_GRANITE_STATUE then
            local choice = guard_choice(ctx)

            ctx:set_cell(state.level_id, x, y, terrain.DNGN_FLOOR)
            ctx:set_cell_colour(state.level_id, x, y, colours.LIGHTGREY)

            local actor =
                factory.spawn(ctx, choice.kind_id, state.level_id, x, y, {
                    base_id = choice.base_id,
                    generate_awake = true,
                })

            ctx:add(actor, component.WORLD_VAULT_SPAWN, {
                level_id = state.level_id,
                vault_id = state.vault_id,
                trigger_index = state.record_index,
                target_x = x,
                target_y = y,
            })
        end
    end
end

crypt.grates_drop = grates_drop
crypt.guards_awaken = guards_awaken

return crypt
