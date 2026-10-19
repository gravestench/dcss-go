-- torturous demonspawn (MONS_TORTUROUS_DEMONSPAWN) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_TORTUROUS_DEMONSPAWN",
    status = "removed",
    name = "torturous demonspawn",
}

register.definition(categories.MONSTERS, definition)

return definition
