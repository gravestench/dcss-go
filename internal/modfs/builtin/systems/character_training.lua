local training = require("policy.character.training")

register.system({
    id = "character.training",
    scope = "active",
    query = {},
    after = { "actor.death" },
    before = { "character.advancement" },
    update = function(ctx, actor)
        if actor == ctx:player() then
            training.update(ctx, actor)
        end
    end,
})
