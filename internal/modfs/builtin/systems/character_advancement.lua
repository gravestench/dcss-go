local advancement = require("policy.character.advancement")

register.system({
    id = "character.advancement",
    scope = "active",
    query = {},
    after = { "character.training" },
    before = { "status.duration" },
    update = function(ctx, actor)
        if actor == ctx:player() then
            advancement.advance(ctx, actor)
        end
    end,
})
