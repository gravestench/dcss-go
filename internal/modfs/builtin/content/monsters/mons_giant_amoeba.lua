-- giant amoeba (MONS_GIANT_AMOEBA) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GIANT_AMOEBA",
    status = "removed",
    name = "giant amoeba",
}

register.definition(categories.MONSTERS, definition)

return definition
