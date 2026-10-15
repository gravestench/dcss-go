local learning = require("policy.character.spell_learning")

local system = {}

function system.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    local intent = ctx:get(actor, "core.intent")

    if intent then
        learning.advance(ctx, actor, intent)
    end
end

register.system({
    id = "character.spell_memorisation",
    scope = "active",
    query = {},
    after = { "world.doors" },
    before = { "world.movement" },
    update = system.update,
})

return system
