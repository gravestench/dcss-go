-- giant goldfish (MONS_GIANT_GOLDFISH) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GIANT_GOLDFISH",
    status = "removed",
    name = "giant goldfish",
}

register.definition(categories.MONSTERS, definition)

return definition
