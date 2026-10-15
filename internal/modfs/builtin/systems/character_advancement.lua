local advancement = require("policy.character.advancement")

local system = {}

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
