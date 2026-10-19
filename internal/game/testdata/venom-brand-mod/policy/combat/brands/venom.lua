-- The Venom override applies a fixed five poison and emits a mod-specific hit message.

return {
    -- Fixed poison removes RNG from this fixture, while the emitted message
    -- proves that the overlay's hook handled the hit.
    -- Example: require("policy.combat.brands.venom").apply(ctx, hit, brands).
    apply = function(ctx, hit, brands)
        brands.poison(ctx, 5, hit.source_id)
        ctx:emit("combat", "The modded venom takes hold.")
    end,
}
