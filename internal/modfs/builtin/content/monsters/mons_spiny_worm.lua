-- spiny worm (MONS_SPINY_WORM) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPINY_WORM",
    status = "removed",
    name = "spiny worm",
}

register.definition(categories.MONSTERS, definition)

return definition
