-- The overlaid turn system increments by two while retaining its entity-reference identity check.
-- Theory of operation: the same system ID and path replace the base module.
-- It still runs after poison on the active actor, but stores increments of
-- two so the integration test can detect which layer supplied the callback.

register.system{
    id = "mod.count_turns",
    scope = "active",
    after = { "status.poison" },
    -- Keep the owner identity check from the base system so an override does
    -- not conceal a save/restore handle mismatch behind a changed increment.
    update = function(ctx, entity)
        local turns = ctx:get(entity, "mod.turns")

        if turns == nil then
            ctx:add(entity, "mod.turns", {
                count = 2,
                owner = entity,
            })
            return
        end

        if turns.owner ~= entity then
            error("entity reference lost identity")
        end

        ctx:set(entity, "mod.turns", {
            count = turns.count + 2,
            owner = entity,
        })
    end,
}
