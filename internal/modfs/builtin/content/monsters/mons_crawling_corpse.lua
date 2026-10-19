-- crawling corpse (MONS_CRAWLING_CORPSE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_CRAWLING_CORPSE",
    status = "removed",
    name = "crawling corpse",
}

register.definition(categories.MONSTERS, definition)

return definition
