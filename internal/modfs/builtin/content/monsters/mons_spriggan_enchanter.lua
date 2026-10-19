-- spriggan enchanter (MONS_SPRIGGAN_ENCHANTER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPRIGGAN_ENCHANTER",
    status = "removed",
    name = "spriggan enchanter",
}

register.definition(categories.MONSTERS, definition)

return definition
