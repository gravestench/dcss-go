-- war dog (MONS_WAR_DOG) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_WAR_DOG",
    status = "removed",
    name = "war dog",
}

register.definition(categories.MONSTERS, definition)

return definition
