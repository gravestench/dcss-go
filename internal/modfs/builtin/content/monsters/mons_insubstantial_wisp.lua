-- mons_insubstantial_wisp (MONS_INSUBSTANTIAL_WISP) is a retained enum_only source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/monster-type.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_INSUBSTANTIAL_WISP",
    status = "enum_only",
}

register.definition(categories.MONSTERS, definition)

return definition
