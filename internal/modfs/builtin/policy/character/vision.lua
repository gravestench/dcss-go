-- Example: Nightstalker reduces the ordinary seven-cell sight radius before rendering.
-- Source: player.cc:update_vision_range.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")

local vision = {}

-- Nightstalker changes the radius read by sight callers without mutating the level visibility grid.
function vision.radius(ctx, player)
    return 7 + effects.sum(ctx, player,
        capabilities.VISION_RADIUS_BONUS)
end

-- Expose the current player radius through the registered vision query.
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
