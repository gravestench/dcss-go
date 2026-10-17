local catalog = require("policy.catalog")
local ids = require("ids.items")

local books = {}

-- Source: shopping.cc:item_value, OBJ_BOOKS.
function books.value(kind, _, _, _, options)
    if kind.id == ids.BOOK_MANUAL then
        return 800
    end

    if kind.id == ids.BOOK_BUGGY_DESTRUCTION then
        return 0
    end

    local spells = options and options.spells or
        kind.generation and kind.generation.spells or {}
    local levels = 0

    for _, id in ipairs(spells) do
        levels = levels + catalog.get("spells", id).level
    end

    return 20 * levels + 20 * #spells
end

return books
