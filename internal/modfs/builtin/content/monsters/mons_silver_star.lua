-- silver star (MONS_SILVER_STAR) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SILVER_STAR",
    status = "removed",
    name = "silver star",
}

register.definition(categories.MONSTERS, definition)

return definition
