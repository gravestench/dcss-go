-- hungry ghost (MONS_HUNGRY_GHOST) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HUNGRY_GHOST",
    status = "removed",
    name = "hungry ghost",
}

register.definition(categories.MONSTERS, definition)

return definition
