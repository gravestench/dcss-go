-- deep dwarf artificer (MONS_DEEP_DWARF_ARTIFICER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_DWARF_ARTIFICER",
    status = "removed",
    name = "deep dwarf artificer",
}

register.definition(categories.MONSTERS, definition)

return definition
