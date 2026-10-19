-- rakshasa fake (MONS_RAKSHASA_FAKE) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_RAKSHASA_FAKE",
    status = "removed",
    name = "rakshasa fake",
}

register.definition(categories.MONSTERS, definition)

return definition
