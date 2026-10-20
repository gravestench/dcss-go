-- Theory of operation: each undead child runs the source init_undead
-- helper after its local map directives. The hook adds graveyard floor
-- presentation, optional black-smoke markers, depth-scaled undead, and
-- the source gravestone name as a typed placement record.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local setup = {}

local FOG_MARKER = 'lua:fog_machine { pow_max = 10, delay_min = 10, ' ..
    'delay_max = 10, size = 5, start_clouds = 1, ' ..
    'cloud_type = "black smoke" }'

local undead_choices = {
    shallow = '.-_ = zombie / skeleton / w:300 nothing',
    early = '.-_ = w:25 zombie / skeleton / w:5 phantom / w:300 nothing',
    middle = '.-_ = w:30 zombie / w:20 wight / w:300 nothing',
    deep = '.-_ = w:30 zombie / w:10 wraith / w:10 vampire / ' ..
        'w:10 shadow / w:300 nothing',
    bottom = '.-_ = w:30 zombie / w:5 shadow / w:5 wraith / ' ..
        'w:5 vampire / w:15 skeletal warrior / w:300 nothing',
}

-- Keep marker creation between the two S substitutions. The source
-- places smoke on some graveyards but leaves their final floor walkable.
local function emit_fog(api)
    api:emit(directives.SUBST, "S = .....S")
    api:record(effects.MARKER, {
        glyph = "S",
        identity = FOG_MARKER,
    })
    api:emit(directives.SUBST, "S = .")
end

-- Choose the source monster mix from absolute depth, then retain the
-- gravestone's presentation name as level data for inspection and saves.
local function configure(api)
    local depth = api:absolute_depth()
    local monsters = undead_choices.bottom

    api:emit(directives.FTILE, "- = floor_pebble_brown")
    api:emit(directives.FTILE, "_ = floor_pebble_darkgray")
    api:emit(directives.COLOUR, "- = brown")
    emit_fog(api)

    if depth <= 3 then
        monsters = undead_choices.shallow
    elseif depth <= 6 then
        monsters = undead_choices.early
    elseif depth <= 9 then
        monsters = undead_choices.middle
    elseif depth <= 12 then
        monsters = undead_choices.deep
    end

    api:emit(directives.KMONS, monsters)
    api:emit(directives.KMONS, "t = withered plant")
    api:emit(directives.TILE, "G = dngn_gravestone")
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

setup.configure = configure

return setup
