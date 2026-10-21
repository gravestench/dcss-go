-- Names come from the winning layered god definitions. A mod that replaces
-- one god file changes display and altar tags through the same catalog record.
local categories = require("constants.catalog")
local gods = require("constants.gods")

local names = {
    [gods.NO_GOD] = "no god",
    [gods.ECUMENICAL] = "an unknown god",
}

for _, id in ipairs(register.ids(categories.GODS)) do
    names[id] = register.get(categories.GODS, id).name
end

return names
