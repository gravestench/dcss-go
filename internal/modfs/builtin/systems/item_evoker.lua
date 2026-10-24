-- Theory of operation: the committed evoke intent runs after player
-- spell and wand actions but before movement. The item effect decides
-- whether this turn spent XP debt; the system only dispatches.
local intent = require("constants.intent")
local evokers = require("policy.inventory.evokers")

local system = {}

-- Resolve only the player action. Monster effects use their own systems.
function system.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local chosen = ctx:get(actor, "core.intent")

    if chosen and chosen.kind == intent.EVOKE_ITEM then
        evokers.resolve(ctx, actor, chosen, aut)
    end
end

register.system({
    id = "item.evoker",
    scope = "active",
    query = {},
    after = { "item.wand" },
    before = { "world.movement" },
    update = system.update,
})

return system
