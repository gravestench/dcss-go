-- lava worm (MONS_LAVA_WORM) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LAVA_WORM",
    status = "removed",
    name = "lava worm",
}

register.definition(categories.MONSTERS, definition)

return definition
