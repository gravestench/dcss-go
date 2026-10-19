local books = require("policy.item_generation.books")
local catalog = require("policy.item_generation.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local pool = require("policy.item_generation.pool")
local source = require("policy.item_generation.source_roll")

local policy = {}

-- Example: policy.eligible(nil, book_kind, request) accepts a requested fixed book but not an unrequested one.
-- A random book needs a positive depth weight; explicit kinds bypass that weight but still need a generation mode.
function policy.eligible(_, definition, request)
    if definition.class ~= classes.OBJ_BOOKS then
        return false
    end

    if request.kind_id == definition.id then
        return definition.generation.mode ~= "none"
    end

    return definition.generation.mode == "random" and
        books.weight(definition, request.depth) > 0
end

-- An explicit weight overrides the depth-derived spell-level weight.
function policy.weight(_, definition, request)
    return definition.generation.weight or
        books.weight(definition, request.depth)
end

-- Roll manuals and rare randart books around the ordinary weighted book pool.
function policy.pick(ctx, request)
    -- Source: crawl-ref/source/makeitem.cc.
    if source.chance(ctx, 21 + request.depth, 4200) then
        return require("policy.catalog").get("items", ids.BOOK_MANUAL)
    end

    local definition = pool.select(ctx, classes.OBJ_BOOKS, request, policy)

    if request.allow_uniques and
        source.chance(ctx, 101 + request.depth * 3, 4000) then
        local randart = source.weighted_id(ctx, {
            {
                id = ids.BOOK_RANDART_THEME,
                weight = 29,
            },
            {
                id = ids.BOOK_RANDART_LEVEL,
                weight = 1,
            },
        })

        return require("policy.catalog").get("items", randart)
    end

    return definition
end

-- Delegate special book contents after the base kind is fixed.
function policy.roll(ctx, definition, request, result)
    books.roll(ctx, definition, request, result)
end

catalog.register(classes.OBJ_BOOKS, policy)

return policy
