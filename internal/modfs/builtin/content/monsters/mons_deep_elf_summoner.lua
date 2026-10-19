-- deep elf summoner (MONS_DEEP_ELF_SUMMONER) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_DEEP_ELF_SUMMONER",
    status = "removed",
    name = "deep elf summoner",
}

register.definition(categories.MONSTERS, definition)

return definition
