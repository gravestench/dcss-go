-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local appearance = require("policy.generation.vaults.crypt.appearance")

local handler = {}

-- Keep the dead-tree description local to this map.
-- Source operation:
-- : set_feature_name("tree", "dead tree")
local function name_dead_trees(api)
    appearance.dead_tree(api)
end

handler.name_dead_trees = name_dead_trees

return handler
