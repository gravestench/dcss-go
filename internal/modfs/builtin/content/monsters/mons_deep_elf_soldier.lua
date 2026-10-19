-- deep elf soldier (MONS_DEEP_ELF_SOLDIER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_ELF_SOLDIER",
    status = "removed",
    name = "deep elf soldier",
}

register.definition(categories.MONSTERS, definition)

return definition
