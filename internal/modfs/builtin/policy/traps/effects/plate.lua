-- Source: traps.cc:754-755. Vault marker systems can subscribe to this
-- position event without being coupled to the generic trap dispatcher.
local effect = {}

function effect.trigger(ctx, trap, actor, site)
    ctx:signal("trap.pressure_plate", {
        actor = actor,
        trap = trap,
        level_id = site.level_id,
        x = site.x,
        y = site.y,
    })
end

return effect
