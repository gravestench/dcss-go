local egos = require("constants.armour_egos")
local ids = require("ids.items")
local source = require("policy.item_generation.source_roll")

local armour_egos = {}

-- Source: crawl-ref/source/makeitem.cc. Each subtype keeps its
-- own source order and weights; zero-weight entries are not synthesized.
local tables = {
    [ids.ARM_BUCKLER] = {
        {
            id = egos.RESISTANCE,
            weight = 1,
        },
        {
            id = egos.FIRE_RESISTANCE,
            weight = 3,
        },
        {
            id = egos.COLD_RESISTANCE,
            weight = 3,
        },
        {
            id = egos.POISON_RESISTANCE,
            weight = 3,
        },
        {
            id = egos.POSITIVE_ENERGY,
            weight = 3,
        },
        {
            id = egos.REFLECTION,
            weight = 6,
        },
        {
            id = egos.PROTECTION,
            weight = 12,
        },
    },
    [ids.ARM_ORB] = {
        {
            id = egos.LIGHT,
            weight = 1,
        },
        {
            id = egos.RAGE,
            weight = 1,
        },
        {
            id = egos.MAYHEM,
            weight = 1,
        },
        {
            id = egos.GUILE,
            weight = 1,
        },
        {
            id = egos.ENERGY,
            weight = 1,
        },
    },
    [ids.ARM_SCARF] = {
        {
            id = egos.RESISTANCE,
            weight = 1,
        },
        {
            id = egos.REPULSION,
            weight = 1,
        },
        {
            id = egos.INVISIBILITY,
            weight = 1,
        },
        {
            id = egos.HARM,
            weight = 1,
        },
        {
            id = egos.SHADOWS,
            weight = 1,
        },
    },
    [ids.ARM_CLOAK] = {
        {
            id = egos.POISON_RESISTANCE,
            weight = 1,
        },
        {
            id = egos.WILLPOWER,
            weight = 1,
        },
        {
            id = egos.STEALTH,
            weight = 1,
        },
        {
            id = egos.PRESERVATION,
            weight = 1,
        },
    },
    [ids.ARM_HAT] = {
        {
            id = egos.NORMAL,
            weight = 10,
        },
        {
            id = egos.STEALTH,
            weight = 3,
        },
        {
            id = egos.WILLPOWER,
            weight = 3,
        },
        {
            id = egos.INTELLIGENCE,
            weight = 2,
        },
        {
            id = egos.SEE_INVISIBLE,
            weight = 2,
        },
    },
    [ids.ARM_HELMET] = {
        {
            id = egos.SEE_INVISIBLE,
            weight = 1,
        },
        {
            id = egos.INTELLIGENCE,
            weight = 1,
        },
    },
    [ids.ARM_GLOVES] = {
        {
            id = egos.DEXTERITY,
            weight = 1,
        },
        {
            id = egos.STRENGTH,
            weight = 1,
        },
        {
            id = egos.HURLING,
            weight = 1,
        },
        {
            id = egos.STEALTH,
            weight = 1,
        },
        {
            id = egos.INFUSION,
            weight = 1,
        },
    },
    [ids.ARM_BOOTS] = {
        {
            id = egos.FLYING,
            weight = 1,
        },
        {
            id = egos.STEALTH,
            weight = 1,
        },
        {
            id = egos.RAMPAGING,
            weight = 1,
        },
    },
    [ids.ARM_BARDING] = {
        {
            id = egos.FLYING,
            weight = 1,
        },
        {
            id = egos.STEALTH,
            weight = 1,
        },
        {
            id = egos.COLD_RESISTANCE,
            weight = 1,
        },
        {
            id = egos.FIRE_RESISTANCE,
            weight = 1,
        },
    },
    [ids.ARM_ROBE] = {
        {
            id = egos.RESISTANCE,
            weight = 1,
        },
        {
            id = egos.ARCHMAGI,
            weight = 1,
        },
        {
            id = egos.NORMAL,
            weight = 2,
        },
        {
            id = egos.COLD_RESISTANCE,
            weight = 2,
        },
        {
            id = egos.FIRE_RESISTANCE,
            weight = 2,
        },
        {
            id = egos.POSITIVE_ENERGY,
            weight = 2,
        },
        {
            id = egos.WILLPOWER,
            weight = 4,
        },
    },
    [ids.ARM_PLATE_ARMOUR] = {
        {
            id = egos.FIRE_RESISTANCE,
            weight = 26,
        },
        {
            id = egos.COLD_RESISTANCE,
            weight = 26,
        },
        {
            id = egos.POISON_RESISTANCE,
            weight = 19,
        },
        {
            id = egos.WILLPOWER,
            weight = 15,
        },
        {
            id = egos.POSITIVE_ENERGY,
            weight = 7,
        },
        {
            id = egos.PONDEROUSNESS,
            weight = 7,
        },
    },
}

tables[ids.ARM_KITE_SHIELD] = tables[ids.ARM_BUCKLER]
tables[ids.ARM_TOWER_SHIELD] = tables[ids.ARM_BUCKLER]

local body = {
    {
        id = egos.FIRE_RESISTANCE,
        weight = 7,
    },
    {
        id = egos.COLD_RESISTANCE,
        weight = 7,
    },
    {
        id = egos.POISON_RESISTANCE,
        weight = 5,
    },
    {
        id = egos.WILLPOWER,
        weight = 4,
    },
    {
        id = egos.POSITIVE_ENERGY,
        weight = 2,
    },
}

local no_ego = {
    [ids.ARM_ANIMAL_SKIN] = true,
    [ids.ARM_CRYSTAL_PLATE_ARMOUR] = true,
    [ids.ARM_TROLL_HIDE] = true,
    [ids.ARM_TROLL_LEATHER_ARMOUR] = true,
    [ids.ARM_FIRE_DRAGON_HIDE] = true,
    [ids.ARM_FIRE_DRAGON_ARMOUR] = true,
    [ids.ARM_ICE_DRAGON_HIDE] = true,
    [ids.ARM_ICE_DRAGON_ARMOUR] = true,
    [ids.ARM_STEAM_DRAGON_HIDE] = true,
    [ids.ARM_STEAM_DRAGON_ARMOUR] = true,
    [ids.ARM_ACID_DRAGON_HIDE] = true,
    [ids.ARM_ACID_DRAGON_ARMOUR] = true,
    [ids.ARM_STORM_DRAGON_HIDE] = true,
    [ids.ARM_STORM_DRAGON_ARMOUR] = true,
    [ids.ARM_GOLD_DRAGON_HIDE] = true,
    [ids.ARM_GOLD_DRAGON_ARMOUR] = true,
    [ids.ARM_SWAMP_DRAGON_HIDE] = true,
    [ids.ARM_SWAMP_DRAGON_ARMOUR] = true,
    [ids.ARM_PEARL_DRAGON_HIDE] = true,
    [ids.ARM_PEARL_DRAGON_ARMOUR] = true,
    [ids.ARM_SHADOW_DRAGON_HIDE] = true,
    [ids.ARM_SHADOW_DRAGON_ARMOUR] = true,
    [ids.ARM_QUICKSILVER_DRAGON_HIDE] = true,
    [ids.ARM_QUICKSILVER_DRAGON_ARMOUR] = true,
}

-- Example: armour_egos.allowed(hide_kind) returns false for a hide on the no-ego list.
-- Check the hard no-ego set before any subtype table can spend an ego draw.
function armour_egos.allowed(definition)
    return not no_ego[definition.id]
end

-- A hide in no_ego spends no brand draw; other armour uses its subtype table or the body fallback.
function armour_egos.roll(ctx, definition)
    if not armour_egos.allowed(definition) then
        return egos.NORMAL
    end

    return source.weighted_id(ctx, tables[definition.id] or body)
end

return armour_egos
