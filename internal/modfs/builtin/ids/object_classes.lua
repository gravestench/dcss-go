-- Item declarations own the set of object classes used by this ruleset.
local classes = {}
local catalog = require("policy.catalog")

for _, definition in ipairs(catalog.all("items")) do
    classes[definition.class] = definition.class
end

return classes
