local advancement = require("policy.character.advancement")

local system = {}

-- Theory of operation: Any acting creature can cause a death credited to
-- the player. Advance that one player after the award and skill training,
-- before duration effects or a save can observe mismatched XP and level.
function system.update(ctx)
    local player = ctx:player()

    if player then
        advancement.advance(ctx, player)
    end
end

register.system({
    id = "character.advancement",
    scope = "active",
    query = {},
    after = { "character.training" },
    before = { "status.duration" },
    update = system.update,
})

return system
