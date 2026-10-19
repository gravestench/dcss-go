-- Example: Use player-shaped remains only after a game starts and the species can leave a body.
local effects = require("constants.vault_effects")
local species_ids = require("ids.species")

local handler = {}

local corpseless_species = {
    [species_ids.SP_VAMPIRE] = true,
    [species_ids.SP_MUMMY] = true,
    [species_ids.SP_GHOUL] = true,
    [species_ids.SP_OCTOPODE] = true,
    [species_ids.SP_GARGOYLE] = true,
    [species_ids.SP_VINE_STALKER] = true,
    [species_ids.SP_DJINNI] = true,
    [species_ids.SP_FORMICID] = true,
}

local humanoid_allies = {
    "dwarf",
    "human",
}

local axis_enemies = {
    "goblin",
    "gnoll",
    "kobold",
    "orc",
}

-- Use player-shaped remains only after a game starts and the species can leave a body.
local function ally_remains(api, humanoid_ally)
    if not api:game_started() or corpseless_species[api:player_species()] then
        return humanoid_ally
    end

    return api:player_monster()
end

-- Draw the humanoid ally even when player-species remains replace it; enemy selection follows.
local function schedule_battle_remains(api)
    local humanoid_ally = api:random_from(humanoid_allies)
    local ally = ally_remains(api, humanoid_ally)
    local axis = api:random_from(axis_enemies)

    api:record(effects.DELAYED_DECAY, {
        glyph = "u",
        alternatives = ally .. " skeleton",
    })

    api:record(effects.DELAYED_DECAY, {
        glyph = "v",
        alternatives = axis .. " skeleton",
    })
end

handler.schedule_battle_remains = schedule_battle_remains

return handler
