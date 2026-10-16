local quality = require("constants.vault_item_quality")

local source_level = {}

function source_level.request(request)
    -- Source: crawl-ref/source/dungeon.cc:4783-4802 and
    -- crawl-ref/source/mapdef.h:552-553. The * vault shorthand has already
    -- received its 5 + depth * 2 boost when the vault record was parsed.
    local adjusted = {}

    for name, value in pairs(request) do
        adjusted[name] = value
    end

    if request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        adjusted.depth = 351
    end

    return adjusted
end

return source_level
