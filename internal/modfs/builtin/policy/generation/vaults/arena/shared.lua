-- Arena DES files own the four original maps. This named hook ports the
-- shared source script while keeping map-local Lua out of the parser for now.
local directives = require("constants.vault_directives")

local shared = {}

-- All four maps use the same unrotated enclosure, target barrier, spectator
-- cells, and protected exit. The victory owner removes B when the duel ends.
function shared.setup(api)
    api:emit(directives.TAGS, "no_dump no_item_gen allow_dup")
    api:emit(directives.SUBST, "B = o")
    api:emit(directives.KFEAT, "< = exit_arena")
    api:emit(directives.KPROP, "1'< = no_tele_into")
    api:emit(directives.KMASK, "1'< = no_monster_gen")
    api:emit(directives.MONS, "generate_awake spectator")
    api:emit(directives.MARKER,
        'v = lua:props_marker { veto_destroy="veto" }')
end

return shared
