-- rock troll (MONS_ROCK_TROLL) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ROCK_TROLL",
    status = "removed",
    name = "rock troll",
}

register.definition(categories.MONSTERS, definition)

return definition
