local brand = {
    after_death = true,
    requires_damage = true,
}

function brand.apply(ctx, hit, brands)
    brands.damage(ctx, hit, 5)
    ctx:emit("combat", "A modded player flame burns the target.")
end

return brand
