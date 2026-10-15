-- Source: player-reacts.cc:player_reacts_to_monsters and
-- spl-goditem.cc:detect_items(-1).
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local vision = require("policy.character.vision")

local detection = {}

function detection.jelly_radius(level)
    return level > 0 and 5 or 0
end

function detection.nose_radius(level)
    return level > 0 and 1 or 0
end

function detection.radius(ctx, sight_radius)
    local player = ctx:player()

    if effects.sum(ctx, player, capabilities.STRONG_NOSE) > 0 then
        return sight_radius
    end

    return effects.sum(ctx, player, capabilities.JELLY_ITEM_DETECTION)
end

function detection.plan(ctx, input)
    local radius = detection.radius(ctx, input.sight_radius)
    local selected = {}

    if radius <= 0 then
        return selected
    end

    for _, item in ipairs(input.items) do
        local distance = math.max(
            math.abs(item.x - input.player_x),
            math.abs(item.y - input.player_y))

        if distance <= radius then
            selected[#selected + 1] = {
                x = item.x,
                y = item.y,
            }
        end
    end

    return selected
end

function detection.run(ctx, input)
    input.sight_radius = vision.radius(ctx, ctx:player())

    return { detected = detection.plan(ctx, input) }
end

effects.add(mutations.MUT_JELLY_GROWTH, {
    [capabilities.JELLY_ITEM_DETECTION] = detection.jelly_radius,
})

effects.add(mutations.MUT_STRONG_NOSE, {
    [capabilities.STRONG_NOSE] = detection.nose_radius,
})

register.policy({
    id = "world.detect_items",
    run = detection.run,
})

return detection
