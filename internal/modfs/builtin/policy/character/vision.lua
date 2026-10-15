-- Source: player.cc:update_vision_range.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")

local vision = {}

function vision.radius(ctx, player)
    return 7 + effects.sum(ctx, player,
        capabilities.VISION_RADIUS_BONUS)
end

function vision.run(ctx)
    return {
        radius = vision.radius(ctx, ctx:player()),
    }
end

register.policy({
    id = "character.vision",
    run = vision.run,
})

return vision
