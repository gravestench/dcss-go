-- brain worm (MONS_BRAIN_WORM) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BRAIN_WORM",
    status = "removed",
    name = "brain worm",
}

register.definition(categories.MONSTERS, definition)

return definition
