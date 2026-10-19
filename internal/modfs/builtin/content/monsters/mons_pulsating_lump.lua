-- pulsating lump (MONS_PULSATING_LUMP) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_PULSATING_LUMP",
    status = "removed",
    name = "pulsating lump",
}

register.definition(categories.MONSTERS, definition)

return definition
