-- anubis guard (MONS_ANUBIS_GUARD) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANUBIS_GUARD",
    status = "removed",
    name = "anubis guard",
}

register.definition(categories.MONSTERS, definition)

return definition
