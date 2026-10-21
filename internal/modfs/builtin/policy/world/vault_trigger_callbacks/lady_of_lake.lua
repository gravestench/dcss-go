-- Theory of operation: every Lady of the Lake entrance shares one saved
-- spawn target and one shot. A blocked target leaves the entrances armed,
-- matching the source TriggerableFunction's `data.triggered` state.
local component = require("constants.component")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local senses = require("policy.character.senses")

local handler = {}

-- Place the awake merfolk avatar at the authored K cell when it is free.
-- Visibility changes only the message, never whether the spawn succeeds.
local function spawn(ctx, state)
    local x = state.target_x
    local y = state.target_y

    if not ctx:walkable(state.level_id, x, y) or
        ctx:actor_at(state.level_id, x, y) then
        ctx:emit(channels.VAULT, "The water ripples visibly.")

        return false
    end

    local avatar = factory.spawn(ctx, monsters.MONS_MERFOLK_AVATAR,
        state.level_id, x, y, {
            generate_awake = true,
        })

    -- This actor arrives after the normal vault population pass. Its saved
    -- source marker keeps roster validation tied to the authored encounter.
    ctx:add(avatar, component.WORLD_VAULT_SPAWN, {
        level_id = state.level_id,
        vault_id = state.vault_id,
        trigger_index = state.record_index,
        target_x = x,
        target_y = y,
    })

    local target = {
        level_id = state.level_id,
        x = x,
        y = y,
    }

    if senses.player_sees_cell(ctx, target) then
        ctx:emit(channels.VAULT,
            "A figure emerges from the depths of the water!")
    else
        ctx:emit(channels.VAULT, "The water ripples visibly.")
    end

    return true
end

handler.spawn = spawn

return handler
