-- thorn lotus (MONS_THORN_LOTUS) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_THORN_LOTUS",
    status = "removed",
    name = "thorn lotus",
}

register.definition(categories.MONSTERS, definition)

return definition
