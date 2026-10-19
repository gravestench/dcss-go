-- The base turn system increments by one and checks that saved entity handles remain identical.
-- Theory of operation: after poison resolves, visit only the active actor.
-- Add the counter on the first turn; on later turns, read and rewrite its ECS
-- component. Persisting the owner handle tests save/restore entity identity.

register.system{
    id = "mod.count_turns",
    scope = "active",
    after = { "status.poison" },
    -- Compare the stored owner before incrementing, since a counter on the
    -- wrong entity would otherwise look like a valid numeric progression.
    update = function(ctx, entity)
        local turns = ctx:get(entity, "mod.turns")

        if turns == nil then
            ctx:add(entity, "mod.turns", {
                count = 1,
                owner = entity,
            })
            return
        end

        if turns.owner ~= entity then
            error("entity reference lost identity")
        end

        ctx:set(entity, "mod.turns", {
            count = turns.count + 1,
            owner = entity,
        })
    end,
}
