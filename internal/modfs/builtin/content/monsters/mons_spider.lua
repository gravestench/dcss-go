-- mons_spider (MONS_SPIDER) is a retained enum_only source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/monster-type.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SPIDER",
    status = "enum_only",
}

register.definition(categories.MONSTERS, definition)

return definition
