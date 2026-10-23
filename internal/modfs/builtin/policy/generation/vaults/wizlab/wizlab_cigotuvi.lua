-- wizlab_cigotuvi keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local map = {}

-- Fleshy terrain remains ordinary terrain for movement. These four
-- typed names supply its source descriptions, while DES owns the door
-- marker's authored verbs and the real MAP geometry.
function map.site_1(api)
    local descriptions = {
        {
            feature = features.SHALLOW_WATER,
            name = names.WIZLAB_VISCOUS_FLUID,
        },
        {
            feature = features.STONE_WALL,
            name = names.WIZLAB_SINEWY_WALL,
        },
        {
            feature = features.CLEAR_ROCK_WALL,
            name = names.WIZLAB_THIN_MEMBRANE,
        },
        {
            feature = features.FLOOR,
            name = names.WIZLAB_PULSATING_FLOOR,
        },
    }

    for _, description in ipairs(descriptions) do
        api:record(effects.FEATURE_NAME, description)
    end

    -- The legacy props_marker strings are content: door interaction and
    -- narration can read them later without importing C++ Lua functions.
    local door_properties = table.concat({
        'door_description_noun="fleshy orifice"',
        'door_berserk_verb_open="You part the %s%s"',
        'door_berserk_adjective="with a squelch!"',
        'door_berserk_verb_close="You squeeze the %s%s closed"',
        'door_noisy_verb_open="You part the %s%s with a squelch!"',
        'door_noisy_verb_close="You squeeze the %s%s closed with a squelch!"',
        'door_airborne_verb_open="You reach down and part the %s%s."',
        'door_airborne_verb_close="You reach down and squeeze the %s%s closed."',
        'door_verb_open="You part the %s%s."',
        'door_verb_close="You squeeze the %s%s shut."',
    }, ', ')

    api:emit(directives.MARKER,
        "+ = lua:props_marker { " .. door_properties .. " }")
    shared.setup(api)
    shared.random_monsters(api,
        "large abomination / ugly thing / very ugly thing")
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Cigotuvi's Fleshworks")
end

return map
