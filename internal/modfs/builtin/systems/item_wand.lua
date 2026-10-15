local intent_kinds = require("constants.intent")
local wands = require("policy.inventory.wands")

local system = {}

function system.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local chosen = ctx:get(actor, "core.intent")

    if chosen and chosen.kind == intent_kinds.EVOKE_WAND then
        wands.resolve(ctx, actor, chosen, aut)
    end
end

register.system({
    id = "item.wand",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
