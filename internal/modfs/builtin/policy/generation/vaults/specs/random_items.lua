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

    -- A source acquirement request remains named in the saved record. The
    -- class hints let ordinary vault population materialize a real item;
    -- the distinct request stays available to acquirement policy.
    local themed = name:match("^acquire[:%w_]* (.+)$")

    if themed == "weapon" then
        result.class_id = classes.OBJ_WEAPONS
        result.quality = quality.SUPERB
    elseif themed == "armour" then
        result.class_id = classes.OBJ_ARMOUR
        result.quality = quality.SUPERB
    elseif themed == "jewellery" or themed == "amulet" then
        result.class_id = classes.OBJ_JEWELLERY
        result.quality = quality.SUPERB
    elseif themed == "book" then
        result.class_id = classes.OBJ_BOOKS
        result.quality = quality.SUPERB
    elseif themed == "magical staff" then
        result.class_id = classes.OBJ_STAVES
        result.quality = quality.SUPERB
    elseif themed == "wand" then
        result.class_id = classes.OBJ_WANDS
        result.quality = quality.SUPERB
    elseif name == requests.ANY_WEAPON then
        result.class_id = classes.OBJ_WEAPONS
    elseif name == requests.ANY_ARMOUR then
        result.class_id = classes.OBJ_ARMOUR
    elseif name == requests.ANY_AMULET or
        name == requests.ANY_RING or
        name == requests.ANY_JEWELLERY then
        result.class_id = classes.OBJ_JEWELLERY
    elseif name == requests.ANY_MAGICAL_STAFF then
        result.class_id = classes.OBJ_STAVES
    elseif name == requests.ANY_BOOK then
        result.class_id = classes.OBJ_BOOKS
    elseif name == requests.ANY_SCROLL or
        name == requests.ANY_CONCEALMENT_SCROLL then
        result.class_id = classes.OBJ_SCROLLS
    elseif name == requests.ANY_POTION then
        result.class_id = classes.OBJ_POTIONS
    elseif name == requests.ANY_WAND then
        result.class_id = classes.OBJ_WANDS
    elseif name == requests.ANY_MISC then
        result.class_id = classes.OBJ_MISCELLANY
    elseif name == "$" or name == "random_gold" then
        result.kind_id = ids.OBJ_GOLD
    elseif name == "*" or name == "star_item" then
        result.quality = quality.STAR
        result.depth = 5 + depth * 2
    elseif name == "good_item" or name == requests.ANY_GOOD_ITEM then
        result.quality = quality.GOOD
    elseif name == "|" or name == "superb_item" then
        result.quality = quality.SUPERB
    elseif name ~= "%" and name ~= "random_item" and name ~= "any" then
        error("unknown random vault item request " .. tostring(name))
    end

    return result
end

return random_items
