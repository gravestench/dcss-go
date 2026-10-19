-- grizzly bear (MONS_GRIZZLY_BEAR) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GRIZZLY_BEAR",
    status = "removed",
    name = "grizzly bear",
}

register.definition(categories.MONSTERS, definition)

return definition
