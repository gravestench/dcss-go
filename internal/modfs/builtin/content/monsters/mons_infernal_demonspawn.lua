-- infernal demonspawn (MONS_INFERNAL_DEMONSPAWN) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_INFERNAL_DEMONSPAWN",
    status = "removed",
    name = "infernal demonspawn",
}

register.definition(categories.MONSTERS, definition)

return definition
