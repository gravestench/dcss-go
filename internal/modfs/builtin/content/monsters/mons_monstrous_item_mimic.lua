-- monstrous item mimic (MONS_MONSTROUS_ITEM_MIMIC) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MONSTROUS_ITEM_MIMIC",
    status = "removed",
    name = "monstrous item mimic",
}

register.definition(categories.MONSTERS, definition)

return definition
