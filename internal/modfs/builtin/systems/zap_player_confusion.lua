local zap_ids = require("policy.magic.effects.zaps.ids")

local confusion = {}

-- Theory of operation: Confusion duration is spent before regeneration and the next player action.
-- Confusion duration is decremented after general statuses and before regeneration.
function confusion.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local state = ctx:get(actor, zap_ids.component.PLAYER_CONFUSION)

    if not state then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(actor, zap_ids.component.PLAYER_CONFUSION)
        ctx:emit("duration", "You feel less confused.")
    else
        ctx:set(actor, zap_ids.component.PLAYER_CONFUSION, state)
    end
end

register.system({
    id = "zap.player_confusion.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = confusion.update,
})

return confusion
