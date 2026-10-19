local categories = require("constants.catalog")
local sources = require("constants.poison_sources")
local catalog = require("policy.catalog")

local poison_sources = {}
local fixed = {}

for _, id in pairs(sources) do
    fixed[id] = true
end

-- Poison source IDs must refer to supported actor or environment origins before restore.
-- Example: poison_sources.valid("MONS_ORC") accepts a registered monster as a poison origin.
function poison_sources.valid(id)
    if fixed[id] then
        return true
    end

    local known = pcall(catalog.get, categories.MONSTERS, id)

    return known
end

return poison_sources
