-- A chaos arc chooses its beam effect per contact, using a weighted pool
-- separate from Chaos weapon branding. The listed order fixes draw bands;
-- file discovery order cannot alter a seeded game. Source: beam.cc:
-- _chaos_beam_flavour. Example: a zero draw chooses fire, while the final
-- four draws choose ensnare.
local flavours = require("constants.beam_flavours")

local pool = {}

local choices = {
    {
        flavour = flavours.BEAM_FIRE,
        weight = 70,
    },

    {
        flavour = flavours.BEAM_COLD,
        weight = 70,
    },

    {
        flavour = flavours.BEAM_ELECTRICITY,
        weight = 70,
    },

    {
        flavour = flavours.BEAM_POISON,
        weight = 70,
    },

    {
        flavour = flavours.BEAM_NEG,
        weight = 70,
    },

    {
        flavour = flavours.BEAM_HOLY,
        weight = 35,
    },

    {
        flavour = flavours.BEAM_CONFUSION,
        weight = 14,
    },

    {
        flavour = flavours.BEAM_BANISH,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_BLINK,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_TELEPORT,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_SLOW,
        weight = 10,
    },

    {
        flavour = flavours.BEAM_HASTE,
        weight = 10,
    },

    {
        flavour = flavours.BEAM_INVISIBILITY,
        weight = 10,
    },

    {
        flavour = flavours.BEAM_PARALYSIS,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_PETRIFY,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_BERSERK,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_POLYMORPH,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_ACID,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_LIGHT,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_DAMNATION,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_STICKY_FLAME,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_MINDBURST,
        weight = 5,
    },

    {
        flavour = flavours.BEAM_MIGHT,
        weight = 4,
    },

    {
        flavour = flavours.BEAM_HEALING,
        weight = 4,
    },

    {
        flavour = flavours.BEAM_AGILITY,
        weight = 4,
    },

    {
        flavour = flavours.BEAM_ENSNARE,
        weight = 4,
    },
}

local total_weight = 0

for _, choice in ipairs(choices) do
    total_weight = total_weight + choice.weight
end

-- Draw once from a saved stream. The exact band boundaries match the source
-- list, including its rarity for distortion and beneficial enchantments.
function pool.choose(ctx, stream)
    local draw = ctx:random(stream, total_weight)

    for _, choice in ipairs(choices) do
        draw = draw - choice.weight

        if draw < 0 then
            return choice.flavour
        end
    end

    error("chaos flavour draw exceeded its weighted pool")
end

return pool
