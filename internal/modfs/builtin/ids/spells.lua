-- Spell IDs resolve authored spells across books, casting, and monster slots.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

return catalog.registered(categories.SPELLS)
