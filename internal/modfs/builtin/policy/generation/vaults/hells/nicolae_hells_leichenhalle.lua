-- Theory of operation: this hall has the same geometry in all four Hells,
-- but each branch changes its walls and statues before the map is placed.
-- The source monster and grate declarations remain in its DES file.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Feature names belong to this one map, not to every statue in Hell.
local function rename_statue(api, name)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = name,
    })
end

-- Emit only the source branch's substitutions. Order matters because later
-- DES terrain projection and the shared monster slot see these glyphs.
local function configure(api)
    local branch_id = api:branch_id()

    if branch_id == branches.BRANCH_DIS then
        api:emit(directives.SUBST, "D : !c, E : Gvb, F : G., c : v")
        api:emit(directives.TILE, "G = dngn_statue_iron")
        rename_statue(api, names.IRON_STATUE)
    elseif branch_id == branches.BRANCH_GEHENNA then
        api:emit(directives.SUBST, "D : xc., E : Glcx., F : ..Gl")
    elseif branch_id == branches.BRANCH_COCYTUS then
        api:emit(directives.KFEAT, "1 = W")
        api:emit(directives.SUBST, "D : wc, E : xw, F : .cw")
    elseif branch_id == branches.BRANCH_TARTARUS then
        api:emit(directives.SUBST, "D : cE, EF = ..G")
        api:emit(directives.TILE, "G = dngn_crumbled_column")
        rename_statue(api, names.BROKEN_PILLAR)
    else
        error("Hell leichenhalle needs a Hell subbranch")
    end
end

handler.configure = configure

return handler
