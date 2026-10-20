-- Theory of operation: every demonic child runs the source init_demonic
-- helper after its own authored substitutions. Shared tags and weight live
-- in each DES file for catalog selection; this hook adds the terrain,
-- fog marker, and depth-scaled monster instructions in source order.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local setup = {}

local FOG_MARKER = 'lua:fog_machine { pow_max = 10, delay_min = 10, ' ..
    'delay_max = 10, size = 2, start_clouds = 1, ' ..
    'cloud_type = "translocational energy" }'

local demon_choices = {
    early = '._ = ufetubus / white imp / shadow imp / w:5 quasit / w:300 nothing',
    middle = '._ = w:10 quasit / w:30 any common demon / w:300 nothing',
    late = '._ = w:60 any common demon / w:300 nothing',
}

-- A fog seed is only active if the first substitution retains S. Emit
-- its marker between two substitutions so the marker can survive even
-- though the final terrain under it becomes an ordinary floor.
local function emit_fog(api)
    api:emit(directives.SUBST, "S = ......S")
    api:record(effects.MARKER, {
        glyph = "S",
        identity = FOG_MARKER,
    })
    api:emit(directives.SUBST, "S = .")
end

-- Absolute Dungeon depth moves the monster lottery from imps toward
-- common demons; keyed demonic plants and trees remain source features.
local function configure(api)
    local depth = api:absolute_depth()
    local monsters = demon_choices.late

    api:emit(directives.KPROP, "_ = bloody")
    emit_fog(api)

    if depth <= 8 then
        monsters = demon_choices.early
    elseif depth <= 12 then
        monsters = demon_choices.middle
    end

    api:emit(directives.KMONS, monsters)
    api:emit(directives.KMONS, "P = demonic plant")
    api:emit(directives.KFEAT, "t = demonic_tree")
end

setup.configure = configure

return setup
