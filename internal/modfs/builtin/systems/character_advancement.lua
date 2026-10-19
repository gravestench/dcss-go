local advancement = require("policy.character.advancement")

local system = {}

-- Theory of operation: The policy consumes earned XP and writes progression before duration-driven level effects run.
-- Level advancement follows training so newly earned experience is incorporated first.
function system.update(ctx, actor)
    if actor == ctx:player() then
        advancement.advance(ctx, actor)
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
