local system = {}

function system.tick(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local state = ctx:get(actor, "magic.player_paralysis")

    if not state then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(actor, "magic.player_paralysis")
        ctx:emit("duration", "You can move again.")
    else
        ctx:set(actor, "magic.player_paralysis", state)
    end
end

register.system({
    id = "magic.player_paralysis.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.tick,
})

return system
