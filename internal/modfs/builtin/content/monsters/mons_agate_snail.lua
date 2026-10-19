-- agate snail (MONS_AGATE_SNAIL) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_AGATE_SNAIL",
    status = "removed",
    name = "agate snail",
}

register.definition(categories.MONSTERS, definition)

return definition
