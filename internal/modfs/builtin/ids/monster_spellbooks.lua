-- Spellbook IDs select a monster’s weighted spell slots.

local catalog = require("ids.catalog")
local categories = require("constants.catalog")

local books = catalog.registered(categories.MONSTER_SPELLBOOKS)

-- Sentinels used by the source monster definitions, without a book record.
books.MST_NO_SPELLS = "MST_NO_SPELLS"
books.MST_GHOST = "MST_GHOST"

return books
