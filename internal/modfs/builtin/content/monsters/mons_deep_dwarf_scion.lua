-- deep dwarf scion (MONS_DEEP_DWARF_SCION) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_DWARF_SCION",
    status = "removed",
    name = "deep dwarf scion",
}

register.definition(categories.MONSTERS, definition)

return definition
