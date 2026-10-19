-- deep elf fighter (MONS_DEEP_ELF_FIGHTER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_ELF_FIGHTER",
    status = "removed",
    name = "deep elf fighter",
}

register.definition(categories.MONSTERS, definition)

return definition
