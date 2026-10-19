local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local immunity = require("policy.clouds.immunity")
local targets = require("policy.ai.targets")

local wind = {}

-- The source tests immunity to this cloud, not only universal Cloud Mage
-- immunity. Use the same effect hook as cloud exposure and monster avoidance.
local function immune_to(ctx, actor, state, definition)
    if immunity.all(ctx, actor) then
        return true
    end

    local effect = require(definition.effect)

    return effect.immune and effect.immune(ctx, actor, state) or false
end

-- The source level flag is derived from a living, positioned caster here.
-- This avoids saving a second mutable copy that could survive caster death.
function wind.active_level(ctx, level_id)
    for _, caster in ipairs(ctx:query({
        component.MONSTER_STILL_WINDS,
        component.POSITION,
    })) do
        local state = ctx:get(caster, component.MONSTER_STILL_WINDS)
        local position = ctx:get(caster, component.POSITION)
        local health = ctx:get(caster, component.HEALTH)

        if state.remaining_aut > 0 and position.level_id == level_id and
            health and health.current > 0 then
            return true
        end
    end

    return false
end

-- Source AI casts only when an existing cloud threatens an allied monster
-- or an opaque cloud could shelter an immune nearby player.
function wind.useful(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)

    if not origin or wind.active_level(ctx, origin.level_id) or
        targets.allied(ctx, caster) then
        return false
    end

    local player = ctx:player()
    local player_pos = player and ctx:get(player, component.POSITION)

    for _, cloud in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(cloud, component.WORLD_CLOUD)
        local distance = math.max(math.abs(state.x - origin.x),
            math.abs(state.y - origin.y))

        if state.level_id == origin.level_id and distance <= 7 and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                state.x, state.y) then
            local definition = catalog.get(categories.CLOUDS,
                state.kind_id)
            local occupant = ctx:actor_at(state.level_id, state.x, state.y)

            if occupant and occupant ~= caster and
                not targets.enemy(ctx, caster, occupant) and
                not definition.harmless and
                not immune_to(ctx, occupant, state, definition) then
                return true
            end

            local near_player = player_pos and
                player_pos.level_id == origin.level_id and
                math.max(math.abs(state.x - player_pos.x),
                    math.abs(state.y - player_pos.y)) <= 3

            if near_player and state.opaque and
                immune_to(ctx, player, state, definition) then
                return true
            end
        end
    end

    return false
end

-- cloud.cc:start_still_winds clears every extant cloud in this level.
-- Placement later permits only vortex and ink while this status lasts.
function wind.cast(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    ctx:add(caster, component.MONSTER_STILL_WINDS, {
        remaining_aut = duration.protection(ctx, caster),
    })

    for _, cloud in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(cloud, component.WORLD_CLOUD)

        if state.level_id == position.level_id then
            ctx:destroy(cloud)
        end
    end

    ctx:emit("spell", "The air becomes perfectly still.")
end

-- Once the final caster's timer ends, placement observes no active aura.
function wind.tick(ctx, caster, elapsed_aut)
    local state = ctx:get(caster, component.MONSTER_STILL_WINDS)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(caster, component.MONSTER_STILL_WINDS)
        ctx:emit("duration", "The air resumes its normal movements.")
    else
        ctx:set(caster, component.MONSTER_STILL_WINDS, state)
    end
end

return wind
