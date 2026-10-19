-- ravenous item mimic (MONS_RAVENOUS_ITEM_MIMIC) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_RAVENOUS_ITEM_MIMIC",
    status = "removed",
    name = "ravenous item mimic",
}

register.definition(categories.MONSTERS, definition)

return definition
