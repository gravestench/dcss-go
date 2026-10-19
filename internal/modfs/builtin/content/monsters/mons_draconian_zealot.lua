-- draconian zealot (MONS_DRACONIAN_ZEALOT) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DRACONIAN_ZEALOT",
    status = "removed",
    name = "draconian zealot",
}

register.definition(categories.MONSTERS, definition)

return definition
