-- This rare encompass box has the same geometry in all four Hells.
-- The branch selects its monsters, liquid, cloud, floor, and statue style.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Emit one source fog-machine marker with the branch's cloud type.
local function fog_marker(api, cloud)
    api:emit(directives.MARKER,
        'F = lua:fog_machine {cloud_type = "' .. cloud .. '", ' ..
        'pow_min = 8, pow_max = 10, delay = 100, ' ..
        'size_min = 1, size_max = 1, start_clouds = 1, excl_rad = 0 }')
end

-- The map's branch case runs before the common KPROP and MAP projection.
function handler.configure(api)
    local branch_id = api:branch_id()

    if branch_id == branches.BRANCH_GEHENNA then
        api:emit(directives.MONS, "zombie / skeleton")
        api:emit(directives.MONS, "brimstone fiend / hellephant")
        fog_marker(api, "flame")
        api:emit(directives.SUBST, "~ = l")
        api:emit(directives.FTILE, "F = floor_volcanic")
        api:emit(directives.COLOUR, "F = lightred")
    elseif branch_id == branches.BRANCH_COCYTUS then
        api:emit(directives.MONS, "simulacrum")
        api:emit(directives.MONS, "ice fiend / shard shrike")
        fog_marker(api, "freezing vapour")
        api:emit(directives.SUBST, "~ = w")
        api:emit(directives.FTILE, "F = floor_nerves_blue")
        api:emit(directives.COLOUR, "F = lightblue")
    elseif branch_id == branches.BRANCH_TARTARUS then
        api:emit(directives.MONS, "spectral thing")
        api:emit(directives.MONS, "tzitzimitl / tainted leviathan")
        fog_marker(api, "foul pestilence")
        api:emit(directives.SUBST, "~ = G")
        api:emit(directives.FTILE, "F = floor_crystal_squares")
        api:emit(directives.COLOUR, "F = lightmagenta")
    elseif branch_id == branches.BRANCH_DIS then
        api:emit(directives.MONS, "zombie / skeleton")
        api:emit(directives.MONS, "hell sentinel / iron giant")
        api:emit(directives.SUBST, "xc = v, F~ = G")
        api:emit(directives.COLOUR, "G = cyan")
        api:emit(directives.TILE, "G = dngn_statue_iron")
        api:record(effects.FEATURE_NAME, {
            feature = features.GRANITE_STATUE,
            name = names.IRON_STATUE,
        })
    else
        error("monster house needs one of the four Hell branches")
    end
end

return handler
