local quality = require("constants.vault_item_quality")

local source_level = {}

-- Example: GOOD vault loot uses source depth 351; a divine GIFT uses 350.
-- Copy the request before substituting source's special item levels so callers retain their original depth.
function source_level.request(request)
    -- Source: crawl-ref/source/dungeon.cc and
    -- crawl-ref/source/mapdef.h. The * vault shorthand has already
    -- received its 5 + depth * 2 boost when the vault record was parsed.
    local adjusted = {}

    for name, value in pairs(request) do
        adjusted[name] = value
    end

    if request.quality == quality.GIFT then
        adjusted.depth = 350
    elseif request.quality == quality.GOOD or
        request.quality == quality.SUPERB then
        adjusted.depth = 351
    end

    return adjusted
end

return source_level
