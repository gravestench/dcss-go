-- baby alligator (MONS_BABY_ALLIGATOR) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BABY_ALLIGATOR",
    status = "removed",
    name = "baby alligator",
}

register.definition(categories.MONSTERS, definition)

return definition
