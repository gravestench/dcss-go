-- Theory of operation: a rune-looking slot that did not win the unique
-- rune draw still rewards the player. The source uses one chance in thirteen
-- for a shop; every other result asks for a high-quality item.
local directives = require("constants.vault_directives")
local features = require("constants.vault_feature_requests")
local items = require("constants.vault_item_requests")

local handler = {}

-- Emit the chosen keyed directive before the authored one-cell MAP is placed.
local function choose_reward(api)
    if api:one_in(13) then
        api:emit(directives.KFEAT, "o = " .. features.ANY_SHOP)
    else
        api:emit(directives.KITEM, "o = " .. items.ANY_GOOD_ITEM)
    end
end

handler.choose_reward = choose_reward

return handler
