-- spriggan assassin (MONS_SPRIGGAN_ASSASSIN) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPRIGGAN_ASSASSIN",
    status = "removed",
    name = "spriggan assassin",
}

register.definition(categories.MONSTERS, definition)

return definition
