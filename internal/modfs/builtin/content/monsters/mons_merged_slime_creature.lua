-- mons_merged_slime_creature (MONS_MERGED_SLIME_CREATURE) is a retained enum_only source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/monster-type.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MERGED_SLIME_CREATURE",
    status = "enum_only",
}

register.definition(categories.MONSTERS, definition)

return definition
