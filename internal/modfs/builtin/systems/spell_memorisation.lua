local learning = require("policy.character.spell_learning")

local system = {}

-- Theory of operation: Only the player intent advances the memorisation delay before movement.
-- Memorisation delay progresses after door actions and before movement.
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
