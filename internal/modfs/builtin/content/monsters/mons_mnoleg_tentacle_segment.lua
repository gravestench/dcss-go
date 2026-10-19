-- mnoleg tentacle segment (MONS_MNOLEG_TENTACLE_SEGMENT) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MNOLEG_TENTACLE_SEGMENT",
    status = "removed",
    name = "mnoleg tentacle segment",
}

register.definition(categories.MONSTERS, definition)

return definition
