return {
    apply = function(ctx, hit, brands)
        brands.poison(ctx, 5, hit.source_id)
        ctx:emit("combat", "The modded venom takes hold.")
    end,
}
