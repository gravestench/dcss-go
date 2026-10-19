local streams = require("constants.rng_streams")
local classes = require("ids.object_classes")
local quality = require("constants.vault_item_quality")

local choice = {}

-- Source: crawl-ref/source/makeitem.cc.
local ordinary = {
    {
        class = classes.OBJ_STAVES,
        weight = 10,
    },
    {
        class = classes.OBJ_JEWELLERY,
        weight = 45,
    },
    {
        class = classes.OBJ_BOOKS,
        weight = 45,
    },
    {
        class = classes.OBJ_WANDS,
        weight = 70,
    },
    {
        class = classes.OBJ_ARMOUR,
        weight = 210,
    },
    {
        class = classes.OBJ_WEAPONS,
        weight = 210,
    },
    {
        class = classes.OBJ_POTIONS,
        weight = 210,
    },
    {
        class = classes.OBJ_MISSILES,
        weight = 180,
    },
    {
        class = classes.OBJ_SCROLLS,
        weight = 300,
    },
    {
        class = classes.OBJ_GOLD,
        weight = 440,
    },
}

-- Source: crawl-ref/source/dungeon.cc.
local superb = {
    {
        class = classes.OBJ_WEAPONS,
        weight = 20,
    },
    {
        class = classes.OBJ_ARMOUR,
        weight = 10,
    },
    {
        class = classes.OBJ_JEWELLERY,
        weight = 10,
    },
    {
        class = classes.OBJ_BOOKS,
        weight = 10,
    },
    {
        class = classes.OBJ_STAVES,
        weight = 10,
    },
    {
        class = classes.OBJ_MISCELLANY,
        weight = 10,
    },
}

-- Draw a class from source weights on the item-generation stream.
local function weighted(ctx, rows)
    local total = 0

    for _, row in ipairs(rows) do
        total = total + row.weight
    end

    local draw = ctx:random(streams.ITEM_GENERATION, total)

    for _, row in ipairs(rows) do
        if draw < row.weight then
            return row.class
        end

        draw = draw - row.weight
    end

    error("item class draw outside source table")
end

-- Example: choice.pick(ctx, { quality = quality.SUPERB }) draws from the superb class weights.
-- Honor explicit class requests without RNG; ordinary draws then apply depth-specific misc and wand substitutions.
function choice.pick(ctx, request)
    if request.class_id then
        return request.class_id
    end

    if request.quality == quality.SUPERB then
        return weighted(ctx, superb)
    end

    local depth = request.depth
    local class_id = weighted(ctx, ordinary)

    -- Source: makeitem.cc. The misc chance follows class choice.
    if depth > 7 and ctx:random(streams.ITEM_GENERATION, 5000) < 21 + depth then
        class_id = classes.OBJ_MISCELLANY
    end

    if depth < 7 and class_id == classes.OBJ_WANDS and
        ctx:random(streams.ITEM_GENERATION, 7) >= depth then
        if ctx:random(streams.ITEM_GENERATION, 2) == 0 then
            class_id = classes.OBJ_POTIONS
        else
            class_id = classes.OBJ_SCROLLS
        end
    end

    return class_id
end

return choice
