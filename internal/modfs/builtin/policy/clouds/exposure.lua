local categories = require("constants.catalog")
local content = require("policy.catalog")
local immunity = require("policy.clouds.immunity")
local plant_protection = require(
    "policy.religion.fedhas.protection")

local exposure = {}

-- The field invokes this bridge after choosing an occupant and its registered cloud effect.
-- Example: a harmless cloud can still run its effect hook while reporting zero damage.
function exposure.apply(ctx, actor, cloud_entity, state, elapsed_aut)
    local definition = content.get(categories.CLOUDS, state.kind_id)

    if definition.harmless or immunity.all(ctx, actor) then
        return 0
    end

    -- The saved player-side kill category survives a lost source actor.
    -- Source cloud immunity therefore checks attribution at exposure.
    if plant_protection.ignores_cloud(ctx, actor,
        state.kill_category) then
        return 0
    end

    local effect = require(definition.effect)
    local amount = effect.apply(ctx, actor, state,
        elapsed_aut, cloud_entity, definition)

    return amount or 0
end

return exposure
