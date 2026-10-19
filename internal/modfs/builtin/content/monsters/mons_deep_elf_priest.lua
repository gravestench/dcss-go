-- deep elf priest (MONS_DEEP_ELF_PRIEST) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_ELF_PRIEST",
    status = "removed",
    name = "deep elf priest",
}

register.definition(categories.MONSTERS, definition)

return definition
