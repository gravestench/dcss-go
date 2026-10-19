-- rotting devil (MONS_ROTTING_DEVIL) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ROTTING_DEVIL",
    status = "removed",
    name = "rotting devil",
}

register.definition(categories.MONSTERS, definition)

return definition
