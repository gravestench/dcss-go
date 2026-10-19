-- eye of draining (MONS_EYE_OF_DRAINING) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_EYE_OF_DRAINING",
    status = "removed",
    name = "eye of draining",
}

register.definition(categories.MONSTERS, definition)

return definition
