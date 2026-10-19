-- gnome (MONS_GNOME) is a retained removed source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GNOME",
    status = "removed",
    name = "gnome",
}

register.definition(categories.MONSTERS, definition)

return definition
