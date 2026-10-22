-- Jiyva's heavy-hit defence chooses one species for the entire ejection.
-- The summon policy uses the ordered list for its source roll; restore
-- uses the same identities to reject forged god-origin monsters.
local monsters = require("ids.monsters")

local ejectable = {
    ids = {
        monsters.MONS_ACID_BLOB,
        monsters.MONS_AZURE_JELLY,
        monsters.MONS_ROCKSLIME,
        monsters.MONS_QUICKSILVER_OOZE,
    },
    allowed = {},
}

for _, id in ipairs(ejectable.ids) do
    ejectable.allowed[id] = true
end

return ejectable
