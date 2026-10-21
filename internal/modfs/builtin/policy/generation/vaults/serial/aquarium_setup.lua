-- Theory of operation: every aquarium child calls this helper after its
-- own DES declarations. A controller-selected pool width decides whether
-- the D and E bands stay rock or become water. Branch and absolute depth
-- then choose the sealed exhibit's ecology. Opaque and teleport masks keep
-- creatures inside the glass while their source records survive in saves.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local settings = require("constants.vault_settings")
local setup = {}

-- Give all pieces the same pool width for one serial encounter. The
-- increasing empty weight compensates for the larger possible habitat.
local function size_rules(api)
    local size = api:setting(settings.AQUARIUM_POOL_SIZE) or 0

    if size == 0 then
        api:emit(directives.SUBST, "D : x")
        api:emit(directives.SUBST, "E : x")

        return 100
    end

    if size == 1 then
        api:emit(directives.SUBST, "D : w")
        api:emit(directives.SUBST, "E : x")

        return 150
    end

    api:emit(directives.SUBST, "D : w")
    api:emit(directives.SUBST, "E : w")

    return 200
end

-- Every source habitat glyph is opaque and excludes teleport entry and
-- Jiyva effects. Emit each declaration so transformed glyphs retain intent.
local function barrier_rules(api)
    for _, glyph in ipairs({ "w", "_", "W", "l", "!" }) do
        api:emit(directives.KMASK, glyph .. " = opaque")
        api:emit(directives.KPROP, glyph .. " = no_tele_into")
        api:emit(directives.KPROP, glyph .. " = no_jiyva")
    end
end

-- Elf can exhibit a diamond obelisk, so ball lightning and air elementals
-- dominate the alternatives that survive its wind.
local function elf(api, empty)
    api:emit(directives.SUBST, "w = w:" .. (empty + 64) .. " _:1")
    api:emit(directives.KFEAT, "w = w")
    api:emit(directives.KMONS, "w = w:" .. empty .. " nothing / " ..
        "w:50 generate_awake ball lightning / " ..
        "w:5 generate_awake water elemental / " ..
        "w:4 generate_awake air elemental")
    api:emit(directives.KMONS, "_ = diamond obelisk")
end

-- The earliest exhibit is grass and living bushes instead of water.
local function early_grass(api, empty)
    api:emit(directives.SUBST, "w = _")
    api:emit(directives.FTILE, "_ = floor_grass")
    api:emit(directives.COLOUR, "_ = green")
    api:emit(directives.KMONS, "_ = w:" .. empty .. " nothing / " ..
        "w:50 bush / w:8 generate_awake butterfly")
end

-- D:4-6 adds shallow water and small animals in the enclosed habitat.
local function shallow(api, empty)
    api:emit(directives.SUBST, "w = W_")
    api:emit(directives.KFEAT, "W = W")
    api:emit(directives.KMONS, "W = w:" .. empty .. " nothing / " ..
        "w:10 generate_awake bat / " ..
        "w:5 generate_awake frilled lizard")
    api:emit(directives.KMONS, "_ = w:" .. empty .. " nothing / " ..
        "w:50 fungus / w:10 generate_awake bat / " ..
        "w:5 generate_awake frilled lizard")
end

-- D:7-9 introduces deep water and electric eels.
local function eels(api, empty)
    api:emit(directives.KFEAT, "w = w")
    api:emit(directives.KMONS, "w = w:" .. empty .. " nothing / " ..
        "w:3 generate_awake electric eel")
end

-- D:10-12 replaces the eel pool with sea snakes and snapping turtles.
local function sea_creatures(api, empty)
    api:emit(directives.KFEAT, "w = w")
    api:emit(directives.KMONS, "w = w:" .. empty .. " nothing / " ..
        "w:1 generate_awake sea snake / " ..
        "w:4 generate_awake snapping turtle")
end

-- D:13-15 exhibits increasingly large slime creatures.
local function slime(api, empty)
    api:emit(directives.KFEAT, "w = w")
    api:emit(directives.KMONS, "w = w:" .. empty .. " nothing / " ..
        "w:11 generate_awake slime creature / " ..
        "w:3 generate_awake large slime creature / " ..
        "w:1 generate_awake very large slime creature")
end

-- The first deep exhibit turns its sealed water into icy floor.
local function ice_animals(api, empty)
    api:emit(directives.SUBST, "w = _")
    api:emit(directives.FTILE, "_ = floor_ice")
    api:emit(directives.KMONS, "_ = w:" .. empty .. " nothing / " ..
        "w:3 generate_awake polar bear / " ..
        "w:8 generate_awake yak / w:4 generate_awake wolf")
end

-- D:19-21 shows frozen simulacra and keeps the source freezing-vapour
-- machine as a marker at each surviving exclamation glyph.
local function frozen(api, empty)
    api:emit(directives.SUBST, "w = _:20 !:1")
    api:emit(directives.FTILE, "_ = floor_frozen")
    api:emit(directives.KMONS, "_ = w:" .. empty .. " nothing / " ..
        "w:4 generate_awake ice beast / " ..
        "w:1 generate_awake bat simulacrum / " ..
        "w:1 generate_awake hornet simulacrum / " ..
        "w:1 generate_awake orc simulacrum / " ..
        "w:1 generate_awake yaktaur simulacrum / " ..
        "w:1 generate_awake deep troll simulacrum / " ..
        "w:1 generate_awake wolf spider simulacrum / " ..
        "w:1 generate_awake wolf simulacrum / " ..
        "w:1 generate_awake polar bear simulacrum / " ..
        "w:1 generate_awake boulder beetle simulacrum / " ..
        "w:1 generate_awake fire dragon simulacrum / " ..
        "w:1 generate_awake hydra simulacrum")
    api:emit(directives.FTILE, "! = floor_frozen")
    api:record(effects.MARKER, {
        glyph = "!",
        identity = 'lua:fog_machine { walk_dist = 8, pow_min = 5, ' ..
            'pow_max = 20, cloud_type = "freezing vapour", ' ..
            'delay_min = 10, delay_max = 30, size = 1, ' ..
            'start_clouds = 1, excl_rad = -1 }',
    })
end

-- D:22-24 turns the habitat to lava with fire bats and vortices.
local function first_lava(api, empty)
    api:emit(directives.SUBST, "w = l")
    api:emit(directives.KFEAT, "l = l")
    api:emit(directives.KPROP, "l = no_cloud_gen")
    api:emit(directives.KMONS, "l = w:" .. empty .. " nothing / " ..
        "w:20 generate_awake fire vortex / " ..
        "w:8 generate_awake fire bat / " ..
        "w:5 generate_awake lava snake")
end

-- The deepest lava exhibit can carry flame-cloud machines. Its marker
-- creates a saved cloud source when this selected map is populated.
local function deep_lava(api, empty)
    api:emit(directives.SUBST, "w = l:25 !:1")
    api:emit(directives.KFEAT, "l = l")
    api:emit(directives.KPROP, "l = no_cloud_gen")
    api:emit(directives.KMONS, "l = w:" .. empty .. " nothing / " ..
        "w:30 generate_awake fire vortex / " ..
        "w:2 generate_awake salamander / " ..
        "w:5 generate_awake fire elemental")
    api:emit(directives.KFEAT, "! = l")
    api:emit(directives.KPROP, "! = no_cloud_gen")
    api:record(effects.MARKER, {
        glyph = "!",
        identity = 'lua:fog_machine { walk_dist = 8, pow_min = 1, ' ..
            'pow_max = 20, cloud_type = "flame", ' ..
            'delay_min = 5, delay_max = 25, size = 1, ' ..
            'start_clouds = 2, excl_rad = -1 }',
    })
end

-- The source chooses Elf first, then nine absolute-depth bands. Keep the
-- branch decision separate from the biome methods to make each editable.
local function biome(api, empty)
    if api:branch_id() == branches.BRANCH_ELF then
        elf(api, empty)

        return
    end

    local depth = api:absolute_depth()

    if depth <= 3 then
        early_grass(api, empty)
    elseif depth <= 6 then
        shallow(api, empty)
    elseif depth <= 9 then
        eels(api, empty)
    elseif depth <= 12 then
        sea_creatures(api, empty)
    elseif depth <= 15 then
        slime(api, empty)
    elseif depth <= 18 then
        ice_animals(api, empty)
    elseif depth <= 21 then
        frozen(api, empty)
    elseif depth <= 24 then
        first_lava(api, empty)
    else
        deep_lava(api, empty)
    end
end

-- The child hook first applies controller width, then the five source
-- habitat masks, then the chosen biome at this exact DES hook position.
local function configure(api)
    local empty = size_rules(api)

    barrier_rules(api)
    biome(api, empty)
end

setup.configure = configure

return setup
