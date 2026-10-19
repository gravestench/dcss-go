local categories = require("constants.catalog")
local content = require("policy.catalog")
local immunity = require("policy.clouds.immunity")

local exposure = {}

-- The field invokes this bridge after choosing an occupant and its registered cloud effect.
-- Example: a harmless cloud can still run its effect hook while reporting zero damage.
function exposure.apply(ctx, actor, cloud_entity, state, elapsed_aut)
    local definition = content.get(categories.CLOUDS, state.kind_id)

    if definition.harmless or immunity.all(ctx, actor) then
        return 0
    end

    local effect = require(definition.effect)
    local amount = effect.apply(ctx, actor, state,
        elapsed_aut, cloud_entity, definition)

    return amount or 0
end

return exposure
