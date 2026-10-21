-- Theory of operation: every ice shape calls this named source helper at
-- its authored directive position. The branch changes the keyed monster
-- lottery and fog type; shared ice surfaces and arches stay the same.
-- A high weight for "nothing" keeps most possible cells empty.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local setup = {}

local dungeon_monsters = '.- = simulacrum w:20 / death yak w:1 / ' ..
    'wolf / yak / polar bear / white imp w:20 / ufetubus / ' ..
    'ice beast w:15 / w:2000 nothing'
local cocytus_monsters = '.- = simulacrum w:30 / ice fiend w:1 / ' ..
    'blizzard demon w:5 / ice devil w:20 / white imp / ' ..
    'ice beast w:20 / ice dragon w:5 / ' ..
    'ice dragon simulacrum w:5 / w:2000 nothing'

-- Record a typed fog instruction at the surviving ! glyph. Population
-- turns that instruction into a saved ECS machine on the selected floor.
local function fog_seed(api, cloud_type)
    local marker = 'lua:fog_machine { cloud_type = "' .. cloud_type ..
        '", pow_max = 15, delay_min = 50, delay_max = 100, ' ..
        'size = 8, start_clouds = 1 }'

    api:record(effects.MARKER, {
        glyph = "!",
        identity = marker,
    })
end

-- Emit source directives in the same order as init_ice: monster pool,
-- possible floor cracks, surfaces, arches, and finally the fog seed.
local function configure(api)
    local cocytus = api:branch_id() == branches.BRANCH_COCYTUS
    local monsters = cocytus and cocytus_monsters or dungeon_monsters
    local cloud_type = cocytus and "freezing vapour" or "thin mist"

    api:emit(directives.KMONS, monsters)
    api:emit(directives.SUBST, "- = --.")
    api:emit(directives.RTILE, "x = wall_zot_cyan")
    api:emit(directives.COLOUR, "x = white")
    api:emit(directives.COLOUR, ".@! = white")
    api:emit(directives.FTILE, ".xA@G! = floor_ice")
    api:emit(directives.KFEAT, "A = stone_arch")
    api:emit(directives.KFEAT, ".-! = floor")
    fog_seed(api, cloud_type)
end

setup.configure = configure

return setup
