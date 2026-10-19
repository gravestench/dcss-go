-- formicid drone (MONS_FORMICID_DRONE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FORMICID_DRONE",
    status = "removed",
    name = "formicid drone",
}

register.definition(categories.MONSTERS, definition)

return definition
