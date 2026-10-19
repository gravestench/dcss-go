-- spirit wolf (MONS_SPIRIT_WOLF) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPIRIT_WOLF",
    status = "removed",
    name = "spirit wolf",
}

register.definition(categories.MONSTERS, definition)

return definition
