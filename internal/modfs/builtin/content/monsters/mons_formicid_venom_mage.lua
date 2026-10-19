-- formicid venom mage (MONS_FORMICID_VENOM_MAGE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_FORMICID_VENOM_MAGE",
    status = "removed",
    name = "formicid venom mage",
}

register.definition(categories.MONSTERS, definition)

return definition
