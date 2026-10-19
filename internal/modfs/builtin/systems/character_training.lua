local training = require("policy.character.training")

local system = {}

-- Theory of operation: Training commits skill XP before level advancement derives the player’s new thresholds.
-- Training spends gained experience after death rewards and before level advancement.
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
