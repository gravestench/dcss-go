-- The player Flaming override adds a fixed five damage and a distinct combat message.

local brand = {
    after_death = true,
    requires_damage = true,
}

-- Route damage through the shared brand helper so the fixture still honors
-- the hit contract; the custom message identifies the active overlay.
-- Example: brand.apply(ctx, hit, require("policy.combat.player_brands.common")).
function brand.apply(ctx, hit, brands)
    brands.damage(ctx, hit, 5)
    ctx:emit("combat", "A modded player flame burns the target.")
end

return brand
