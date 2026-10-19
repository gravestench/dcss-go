-- moth of suppression (MONS_MOTH_OF_SUPPRESSION) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MOTH_OF_SUPPRESSION",
    status = "removed",
    name = "moth of suppression",
}

register.definition(categories.MONSTERS, definition)

return definition
