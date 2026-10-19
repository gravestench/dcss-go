-- salamander firebrand (MONS_SALAMANDER_FIREBRAND) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SALAMANDER_FIREBRAND",
    status = "removed",
    name = "salamander firebrand",
}

register.definition(categories.MONSTERS, definition)

return definition
