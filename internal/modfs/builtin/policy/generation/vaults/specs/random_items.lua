local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local choice = require("policy.generation.vaults.specs.choice")

local random_items = {}

-- Source: crawl-ref/source/makeitem.cc:1799-1810, dungeon.cc:4769-4778.
local ordinary_classes = {
    { id = classes.OBJ_STAVES, weight = 10 },
    { id = classes.OBJ_JEWELLERY, weight = 45 },
    { id = classes.OBJ_BOOKS, weight = 45 },
    { id = classes.OBJ_WANDS, weight = 70 },
    { id = classes.OBJ_ARMOUR, weight = 210 },
    { id = classes.OBJ_WEAPONS, weight = 210 },
    { id = classes.OBJ_POTIONS, weight = 210 },
    { id = classes.OBJ_MISSILES, weight = 180 },
    { id = classes.OBJ_SCROLLS, weight = 300 },
    { id = classes.OBJ_GOLD, weight = 440 },
}

local superb_classes = {
    { id = classes.OBJ_WEAPONS, weight = 20 },
    { id = classes.OBJ_ARMOUR, weight = 10 },
    { id = classes.OBJ_JEWELLERY, weight = 10 },
    { id = classes.OBJ_BOOKS, weight = 10 },
    { id = classes.OBJ_STAVES, weight = 10 },
    { id = classes.OBJ_MISCELLANY, weight = 10 },
}

local function weighted_class(ctx, rows)
    local total = 0

    for _, row in ipairs(rows) do
        total = total + row.weight
    end

    local draw = ctx:random("vault_items", total)

    for _, row in ipairs(rows) do
        if draw < row.weight then
            return row.id
        end

        draw = draw - row.weight
    end
end

local function available(class_id)
    local items = {}

    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.class == class_id and
            definition.status ~= "removed" and
            definition.status ~= "enum_only" and
            not definition.explicitly_removed and
            definition.name and definition.name ~= "" then
            items[#items + 1] = definition.id
        end
    end

    return items
end

function random_items.pick(ctx, request, depth, site)
    if request == "random_gold" or request == "$" then
        return ids.OBJ_GOLD
    end

    local rows = ordinary_classes

    if request == "superb_item" or request == "|" then
        rows = superb_classes
    end
    local class_id = weighted_class(ctx, rows)
    local options = available(class_id)

    if #options == 0 then
        choice.fail(site, request, "no eligible item in class " .. class_id)
    end

    return options[ctx:random("vault_items", #options) + 1]
end

return random_items
