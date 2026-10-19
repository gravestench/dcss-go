-- deep dwarf berserker (MONS_DEEP_DWARF_BERSERKER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_DWARF_BERSERKER",
    status = "removed",
    name = "deep dwarf berserker",
}

register.definition(categories.MONSTERS, definition)

return definition
