-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local appearance = require("policy.generation.vaults.crypt.appearance")

local handler = {}

-- Choose the map palette from local Crypt depth, not global state.
-- Source operation:
-- : if you.depth() == 1 then
-- SUBST: s = ]})>
-- : elseif you.depth() == dgn.br_depth(you.branch()) then
-- SUBST: s = [{(<
-- : else
-- SUBST: s = ]})>[{(<
-- : end
local function select_depth_palette(api)
    if api:depth() == 1 then
        api:emit(directives.SUBST, "s = ]})>")
    elseif api:depth() == api:branch_bottom() then
        api:emit(directives.SUBST, "s = [{(<")
    else
        api:emit(directives.SUBST, "s = ]})>[{(<")
    end
end

handler.select_depth_palette = select_depth_palette

-- Record delayed decay so skeletons use the resolved map cells.
-- Source operation:
-- : dgn.delayed_decay(_G, 'e', 'human skeleton / orc skeleton / elf skeleton')
local function preserve_skeletons(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "e",
        alternatives = "human skeleton / orc skeleton / elf skeleton",
    })
end

handler.preserve_skeletons = preserve_skeletons

-- Keep the dead-tree description local to this map.
-- Source operation:
-- : set_feature_name("tree", "dead tree")
local function name_dead_trees(api)
    appearance.dead_tree(api)
end

handler.name_dead_trees = name_dead_trees

return handler
