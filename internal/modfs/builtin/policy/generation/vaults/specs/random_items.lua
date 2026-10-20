-- Example: A random-item vault records a request now and resolves its item during placement.
local classes = require("ids.object_classes")
local ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local requests = require("constants.vault_item_requests")

local random_items = {}

-- A vault record is selected during map generation, before an ECS context
-- exists. Keep its source request typed until population can roll the item.
-- Retain a typed random-item request with depth for population to resolve after map placement.
function random_items.describe(name, depth)
    local result = {
        kind_id = classes.OBJ_RANDOM,
        quality = quality.ORDINARY,
        depth = depth,
    }

    if name == requests.ANY_WEAPON then
        result.class_id = classes.OBJ_WEAPONS
    elseif name == requests.ANY_BOOK then
        result.class_id = classes.OBJ_BOOKS
    elseif name == requests.ANY_SCROLL then
        result.class_id = classes.OBJ_SCROLLS
    elseif name == "any potion" then
        result.class_id = classes.OBJ_POTIONS
    elseif name == "any wand" then
        result.class_id = classes.OBJ_WANDS
    elseif name == "$" or name == "random_gold" then
        result.kind_id = ids.OBJ_GOLD
    elseif name == "*" or name == "star_item" then
        result.quality = quality.STAR
        result.depth = 5 + depth * 2
    elseif name == "good_item" then
        result.quality = quality.GOOD
    elseif name == "|" or name == "superb_item" then
        result.quality = quality.SUPERB
    elseif name ~= "%" and name ~= "random_item" and name ~= "any" then
        error("unknown random vault item request " .. tostring(name))
    end

    return result
end

return random_items
