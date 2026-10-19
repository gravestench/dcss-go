-- hyperactive ballistomycete (MONS_HYPERACTIVE_BALLISTOMYCETE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HYPERACTIVE_BALLISTOMYCETE",
    status = "removed",
    name = "hyperactive ballistomycete",
}

register.definition(categories.MONSTERS, definition)

return definition
