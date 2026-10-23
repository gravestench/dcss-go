-- Card definitions name their Lua effect modules. This lookup follows the
-- effective mod catalog, so a replacement card file can change behavior
-- without adding a new switch branch to the deck owner.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local dispatch = {}

-- Resolve the effective definition once for both tier selection and play.
-- A mod may replace the named module through the layered VFS path.
function dispatch.module(card_id)
    local definition = catalog.get(categories.CARDS, card_id)
    local effect = require(definition.effect_module)

    if type(effect) ~= "table" or type(effect.apply) ~= "function" then
        error("card " .. card_id .. " has no Lua apply function")
    end

    return effect
end

-- Pass one resolved card to its named module. The module owns its source
-- rules and may return a target prompt for the pending card action.
function dispatch.apply(ctx, player, card_id, request)
    return dispatch.module(card_id).apply(ctx, player, request)
end

return dispatch
