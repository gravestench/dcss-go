local component = require("constants.component")
local intent_ids = require("constants.intent")
local registry = require("policy.abilities.registry")

local system = {}

function system.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local intent = ctx:get(actor, component.INTENT)

    if intent and intent.kind == intent_ids.PLAYER_ABILITY then
        registry.resolve(ctx, actor, intent, aut)
    end
end

register.system({
    id = "attack.player_ability",
    scope = "active",
    query = { component.PLAYER },
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
