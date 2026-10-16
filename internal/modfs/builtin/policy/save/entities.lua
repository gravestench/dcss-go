local entities = {}

function entities.validate(ctx)
    for _, entity in ipairs(ctx:query({ "core.actor" })) do
        local actor = ctx:get(entity, "core.actor")
        local health = ctx:get(entity, "core.health")
        local combat = ctx:get(entity, "core.combat")
        local position = ctx:get(entity, "core.position")

        if actor.speed < 0 or not health or not combat or not position then
            error("invalid actor " .. ctx:id(entity))
        end
    end

    for _, entity in ipairs(ctx:query({ "core.combat" })) do
        local combat = ctx:get(entity, "core.combat")

        if not ctx:has(entity, "core.actor") or
            combat.shield_blocks < 0 or combat.shield_blocks > 100 then
            error("invalid combat stats for entity " .. ctx:id(entity))
        end
    end

    for _, entity in ipairs(ctx:query({ "core.health" })) do
        local health = ctx:get(entity, "core.health")

        if health.current < 0 or health.max <= 0 or health.current > health.max then
            error("invalid health for entity " .. ctx:id(entity))
        end
    end
end

return entities
