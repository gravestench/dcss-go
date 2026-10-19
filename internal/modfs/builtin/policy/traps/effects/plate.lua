-- Source: traps.cc. Vault marker systems can subscribe to this
-- position event without being coupled to the generic trap dispatcher.
local effect = {}

-- Signal the pressure plate with its actor and cell so listeners can implement the linked event.
-- Example: effect.trigger(ctx, plate, player, site) signals a pressure-plate event with its cell.
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
