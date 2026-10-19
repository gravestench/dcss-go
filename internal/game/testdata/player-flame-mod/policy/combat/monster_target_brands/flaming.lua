-- The player Flaming override adds a fixed five damage and a distinct combat message.

local brand = {
    after_death = true,
    requires_damage = true,
}

-- Route damage through the shared brand helper so the fixture still honors
-- the hit contract; the custom message identifies the active overlay.
-- The overridden monster-target brand runs for a player or monster wielder.
function brand.apply(ctx, hit, brands)
    brands.damage(ctx, hit, 5)
    ctx:emit("combat", "A modded player flame burns the target.")
end

return brand
