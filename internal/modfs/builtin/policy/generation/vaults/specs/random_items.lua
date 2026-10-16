local classes = require("ids.object_classes")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")

local random_items = {}

-- A vault record is selected during map generation, before an ECS context
-- exists. Keep its source request typed until population can roll the item.
function random_items.describe(name, depth)
    local result = {
        kind_id = classes.OBJ_RANDOM,
        quality = quality.ORDINARY,
        depth = depth,
    }

    if name == "$" or name == "random_gold" then
        result.kind_id = ids.OBJ_GOLD
    elseif name == "*" then
        result.quality = quality.STAR
        result.depth = 5 + depth * 2
    elseif name == "good_item" then
        result.quality = quality.GOOD
    elseif name == "|" or name == "superb_item" then
        result.quality = quality.SUPERB
    elseif name ~= "%" and name ~= "random_item" then
        error("unknown random vault item request " .. tostring(name))
    end

    return result
end

return random_items
