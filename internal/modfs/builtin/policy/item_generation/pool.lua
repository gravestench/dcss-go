local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")

local pool = {}

-- Example: pool.select(ctx, classes.OBJ_ARMOUR, request, armour_policy) weights eligible armour kinds.
-- Weighted selection consumes one generation draw across the eligible entries.
function pool.select(ctx, class_id, request, policy)
    local rows = {}
    local total = 0

    for _, definition in ipairs(catalog.all("items")) do
        if definition.class == class_id and
            policy.eligible(ctx, definition, request) then
            local weight = policy.weight(ctx, definition, request)

            if type(weight) ~= "number" or weight < 0 or
                weight % 1 ~= 0 then
                error(request.site .. ": invalid item weight " .. definition.id)
            end

            if weight > 0 then
                rows[#rows + 1] = {
                    definition = definition,
                    weight = weight,
                }
                total = total + weight
            end
        end
    end

    if total == 0 then
        error(request.site .. ": no eligible item in class " .. class_id)
    end

    local draw = ctx:random(streams.ITEM_GENERATION, total)

    for _, row in ipairs(rows) do
        if draw < row.weight then
            return row.definition
        end

        draw = draw - row.weight
    end

    error(request.site .. ": item subtype draw outside source pool")
end

return pool
