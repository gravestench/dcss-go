-- boring beetle (MONS_BORING_BEETLE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_BORING_BEETLE",
    status = "removed",
    name = "boring beetle",
}

register.definition(categories.MONSTERS, definition)

return definition
