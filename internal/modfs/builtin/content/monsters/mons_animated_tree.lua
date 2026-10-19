-- mons_animated_tree (MONS_ANIMATED_TREE) is a retained enum_only source monster ID.
-- This short record does not define active combat stats.

-- Source: crawl-ref/source/monster-type.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_ANIMATED_TREE",
    status = "enum_only",
}

register.definition(categories.MONSTERS, definition)

return definition
