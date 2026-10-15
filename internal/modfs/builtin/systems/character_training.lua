local training = require("policy.character.training")

local system = {}

function system.update(ctx, actor)
    if actor == ctx:player() then
        training.update(ctx, actor)
    end
end

register.system({
    id = "character.training",
    scope = "active",
    query = {},
    after = { "actor.death" },
    before = { "character.advancement" },
    update = system.update,
})

return system
