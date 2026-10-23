-- Theory of operation: source dgn.delayed_decay places a preserved corpse
-- and arms a sight trigger at its authored cell. The item's existing corpse
-- component stores whether decay is paused. The DES record stores the trigger
-- site, so no second clock or duplicate ECS owner is needed. When the player
-- can see that cell, ordinary corpse aging resumes on later world ticks.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local vision = require("policy.character.vision")

local system = {}

-- The corpse may be moved after placement; its immutable vault origin still
-- points to the cell whose source sight trigger controls the preservation.
local function has_source_trigger(ctx, origin)
    for _, record in ipairs(ctx:records_at(origin.level_id,
        origin.spawn_x, origin.spawn_y)) do
        if record.kind == effects.DELAYED_DECAY and
            record.source_id == origin.vault_id and
            not record.overridden then
            return true
        end
    end

    return false
end

-- Sight activates only on the player's current level. Other floors keep
-- their authored corpses fresh until the player actually enters and sees.
function system.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    local player = ctx:get(actor, component.POSITION)

    if not player then
        return
    end

    local radius = vision.radius(ctx, actor)

    for _, entity in ipairs(ctx:query({
        component.CORPSE,
        component.VAULT_ORIGIN,
    })) do
        local corpse = ctx:get(entity, component.CORPSE)
        local origin = ctx:get(entity, component.VAULT_ORIGIN)

        if corpse.never_decays and
            origin.level_id == player.level_id and
            has_source_trigger(ctx, origin) and
            ctx:visible(player.level_id, player.x, player.y,
                radius, origin.spawn_x, origin.spawn_y) then
            corpse.never_decays = false
            ctx:set(entity, component.CORPSE, corpse)
        end
    end
end

register.system({
    id = "world.delayed_decay",
    scope = "active",
    query = {},
    after = { "world.movement", "world.stairs" },
    update = system.update,
})

return system
