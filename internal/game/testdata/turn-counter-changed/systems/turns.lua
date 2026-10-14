register.system{
    id = "mod.count_turns",
    scope = "active",
    after = { "status.poison" },
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
