-- grey rat (MONS_GREY_RAT) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GREY_RAT",
    status = "removed",
    name = "grey rat",
}

register.definition(categories.MONSTERS, definition)

return definition
