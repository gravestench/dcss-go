-- Source: view.cc:_maybe_trigger_shoutitis and mon-util.cc:should_shout_at_mons.
local catalog = require("policy.catalog")
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local noise = require("policy.world.noise")
local vision = require("policy.character.vision")

local system = {}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function eligible(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return not groups.tentacles[actor.kind_id] and
        not has_flag(definition, flags.CONJURED) and
        not has_flag(definition, flags.PROJECTILE) and
        not has_flag(definition, flags.AVATAR)
end

local function newly_visible(ctx, player, origin)
    local candidates = {}
    local sight = vision.radius(ctx, player)

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)
            local visible = health.current > 0 and
                position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    sight, position.x, position.y)
            local seen = ctx:has(monster, component.SEEN_BY_PLAYER)

            if visible and not seen then
                ctx:add(monster, component.SEEN_BY_PLAYER, {
                    visible = true,
                })
                candidates[#candidates + 1] = monster
            elseif seen and not visible then
                ctx:remove(monster, component.SEEN_BY_PLAYER)
            end
        end
    end

    return candidates
end

function system.update(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("screaming player has no position")
    end

    local candidates = newly_visible(ctx, player, origin)
    local level = effects.sum(ctx, player, capabilities.SHOUT_LEVEL)

    if level == 0 then
        return
    end

    for _, monster in ipairs(candidates) do
        if eligible(ctx, monster) and
            ctx:random("mutation", 100) < level * 6 then
            ctx:emit("mutation", "You shout involuntarily!")
            noise.emit(ctx, origin, noise.shout_volume(ctx, player),
                player)

            return
        end
    end
end

register.system({
    id = "character.scream",
    scope = "active",
    query = { component.PLAYER },
    after = { "world.movement" },
    before = { "attack.combat" },
    update = system.update,
})

return system
