-- Example: Use generic human remains during validation or for species without a matching corpse.
local effects = require("constants.vault_effects")
local species_ids = require("ids.species")

local handler = {}

local human_remains_species = {
    [species_ids.SP_VAMPIRE] = true,
    [species_ids.SP_MUMMY] = true,
    [species_ids.SP_GHOUL] = true,
    [species_ids.SP_GARGOYLE] = true,
    [species_ids.SP_VINE_STALKER] = true,
    [species_ids.SP_DJINNI] = true,
}

local corpse_species = {
    [species_ids.SP_FORMICID] = true,
    [species_ids.SP_OCTOPODE] = true,
}

-- Use generic human remains during validation or for species without a matching corpse.
local function remains_monster(api)
    if not api:game_started() or human_remains_species[api:player_species()] then
        return "human"
    end

    return api:player_monster()
end

-- Choose corpse versus skeleton from the player species before writing DES text.
local function remains_type(api)
    if corpse_species[api:player_species()] then
        return "corpse"
    end

    return "skeleton"
end

-- Player name spaces become underscores so corpse specifications remain single DES tokens.
local function schedule_named_remains(api)
    local monster = remains_monster(api)
    local name = api:player_name():gsub(" ", "_")
    local named_corpse = monster .. " name:" .. name .. " corpse"
    local named_remains = monster .. " name:" .. name .. " " .. remains_type(api)

    api:record(effects.DELAYED_DECAY, {
        glyph = "u",
        alternatives = named_corpse,
    })

    api:record(effects.DELAYED_DECAY, {
        glyph = "U",
        alternatives = named_remains,
    })
end

handler.schedule_named_remains = schedule_named_remains

return handler
