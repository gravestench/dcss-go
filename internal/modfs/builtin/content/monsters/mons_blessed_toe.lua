-- blessed toe (MONS_BLESSED_TOE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BLESSED_TOE",
    status = "removed",
    name = "blessed toe",
}

register.definition(categories.MONSTERS, definition)

return definition
