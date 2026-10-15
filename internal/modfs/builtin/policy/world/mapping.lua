local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local mapping = {}

function mapping.quality(level)
    return level
end

function mapping.level(ctx)
    return effects.sum(ctx, ctx:player(), capabilities.PASSIVE_MAPPING)
end

-- Source: map-knowledge.cc:_automap_from and view.cc:magic_mapping.
-- The host supplies stable per-cell difficulty; Lua owns the radius and
-- chance thresholds that decide which terrain to reveal.
function mapping.plan(ctx, input)
    local quality = mapping.level(ctx)

    if quality <= 0 or #input.origins == 0 then
        return {}
    end

    local player = ctx:get(ctx:player(), component.POSITION)

    if not player then
        error("passive mapping requires player position")
    end

    local radius = quality * 8
    local far = math.floor(radius * 7 / 10)
    local very_far = math.floor(radius * 9 / 10)
    local mapped = {}
    local included = {}

    for _, origin in ipairs(input.origins) do
        local min_y = math.max(0, origin.y - radius)
        local max_y = math.min(input.height - 1, origin.y + radius)
        local min_x = math.max(0, origin.x - radius)
        local max_x = math.min(input.width - 1, origin.x + radius)

        for y = min_y, max_y do
            for x = min_x, max_x do
                local distance = math.max(math.abs(player.x - x),
                    math.abs(player.y - y))
                local threshold = 25

                if distance > very_far then
                    threshold = math.floor(threshold / 3)
                elseif distance > far then
                    threshold = math.floor(threshold * 2 / 3)
                end

                local index = y * input.width + x + 1

                if input.difficulty[index] <= threshold and
                    not included[index] then
                    included[index] = true
                    mapped[#mapped + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return mapped
end

function mapping.run_level(ctx)
    return { level = mapping.level(ctx) }
end

effects.add(mutations.MUT_PASSIVE_MAPPING, {
    [capabilities.PASSIVE_MAPPING] = mapping.quality,
})

register.policy({
    id = "world.mapping_level",
    run = mapping.run_level,
})

return mapping
