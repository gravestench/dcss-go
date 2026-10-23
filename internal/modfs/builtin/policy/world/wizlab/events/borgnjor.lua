-- Theory of operation: any monster death on Borgnjor's floor may call
-- one lost soul. A soul bears source provenance, so its own death cannot
-- recursively call another. The ordinary summon owner handles lifetime.
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.world.wizlab.events.summons")
local wizlab = require("constants.wizlab")

local borgnjor = {}

-- Scan the source circle in a stable order and stop after the first
-- successful placement. The chance is drawn before checking collision.
local function call_soul(ctx, state, position)
    local radius = wizlab.BORGNJOR_SOUL_RADIUS

    for y = position.y - radius, position.y + radius do
        for x = position.x - radius, position.x + radius do
            local dx = x - position.x
            local dy = y - position.y

            if dx * dx + dy * dy <= radius * radius and
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.BORGNJOR_CELL_CHANCE_DENOMINATOR) == 0 and
                ctx:walkable(state.level_id, x, y) and
                not ctx:actor_at(state.level_id, x, y) then
                local soul = summons.place(ctx, state,
                    state.marker_index, monsters.MONS_LOST_SOUL,
                    x, y, wizlab.BORGNJOR_SOUL_DURATION_AUT,
                    wizlab.EVENT_ACTOR_BORGNJOR)

                if soul then
                    ctx:emit(channels.WARNING,
                        "A lost soul coalesces out of thin air!")

                    return true
                end
            end
        end
    end

    return false
end

-- The corpse hook runs after the dying actor has been removed. The
-- player must still be present on this exact Wizard Lab floor.
function borgnjor.monster_died(ctx, actor, _, position)
    local provenance = ctx:get(actor,
        component.WORLD_WIZLAB_EVENT_ACTOR)

    if provenance and provenance.kind ==
        wizlab.EVENT_ACTOR_BORGNJOR then
        return false
    end

    local player = ctx:get(ctx:player(), component.POSITION)

    if not player or player.level_id ~= position.level_id then
        return false
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_BORGNJOR,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_BORGNJOR)

        if state.level_id == position.level_id then
            if ctx:random(streams.WIZLAB_EVENTS,
                wizlab.BORGNJOR_DEATH_CHANCE_DENOMINATOR) == 0 then
                call_soul(ctx, state, player)
            end
        end
    end

    return false
end

death_hooks.add("wizlab.borgnjor_souls", borgnjor.monster_died)

return borgnjor
