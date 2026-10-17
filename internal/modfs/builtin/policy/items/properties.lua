local armour = require("constants.armour_egos")
local brands = require("constants.weapon_brands")
local classes = require("ids.object_classes")
local cosmetics = require("constants.item_cosmetics")
local items = require("ids.items")

local properties = {}

-- Source: item-name.cc weapon_brands_verbose and brand_prefers_adj.
local weapon_names = {
    [brands.FLAMING] = "flaming",
    [brands.FREEZING] = "freezing",
    [brands.HOLY_WRATH] = "holy wrath",
    [brands.ELECTROCUTION] = "electrocution",
    [brands.VENOM] = "venom",
    [brands.PROTECTION] = "protection",
    [brands.DRAINING] = "draining",
    [brands.SPEED] = "speed",
    [brands.VORPAL] = "vorpal",
    [brands.VAMPIRISM] = "vampirism",
    [brands.PAIN] = "pain",
    [brands.ANTIMAGIC] = "antimagic",
    [brands.DISTORTION] = "distortion",
    [brands.CHAOS] = "chaos",
    [brands.SPECTRAL] = "spectralizing",
    [brands.CONFUSE] = "confusion",
}

local weapon_adjectives = {
    [brands.VAMPIRISM] = "vampiric",
    [brands.ANTIMAGIC] = "antimagic",
    [brands.VORPAL] = "vorpal",
    [brands.SPECTRAL] = "spectral",
}

-- Source: item-name.cc armour_ego_name.
local armour_names = {
    [armour.PROTECTION] = "protection",
    [armour.RESISTANCE] = "resistance",
    [armour.FIRE_RESISTANCE] = "fire resistance",
    [armour.COLD_RESISTANCE] = "cold resistance",
    [armour.POISON_RESISTANCE] = "poison resistance",
    [armour.SEE_INVISIBLE] = "see invisible",
    [armour.INVISIBILITY] = "invisibility",
    [armour.STRENGTH] = "strength",
    [armour.DEXTERITY] = "dexterity",
    [armour.INTELLIGENCE] = "intelligence",
    [armour.PONDEROUSNESS] = "ponderousness",
    [armour.FLYING] = "flying",
    [armour.POSITIVE_ENERGY] = "positive energy",
    [armour.SPIRIT_SHIELD] = "spirit shield",
    [armour.WILLPOWER] = "willpower",
    [armour.GUILE] = "guile",
    [armour.STEALTH] = "stealth",
    [armour.ARCHMAGI] = "the Archmagi",
    [armour.PRESERVATION] = "preservation",
    [armour.REFLECTION] = "reflection",
    [armour.HURLING] = "hurling",
    [armour.REPULSION] = "repulsion",
    [armour.HARM] = "harm",
    [armour.SHADOWS] = "shadows",
    [armour.RAMPAGING] = "rampaging",
    [armour.INFUSION] = "infusion",
    [armour.LIGHT] = "light",
    [armour.RAGE] = "wrath",
    [armour.MAYHEM] = "mayhem",
    [armour.ENERGY] = "energy",
}

local embroidered = {
    [items.ARM_ROBE] = true,
    [items.ARM_CLOAK] = true,
    [items.ARM_GLOVES] = true,
    [items.ARM_BOOTS] = true,
    [items.ARM_SCARF] = true,
    [items.ARM_HAT] = true,
}

local dyed = {
    [items.ARM_LEATHER_ARMOUR] = true,
    [items.ARM_ANIMAL_SKIN] = true,
}

function properties.cosmetic(kind, cosmetic, base)
    if cosmetic == cosmetics.NONE then
        return base
    end

    if cosmetic == cosmetics.GLOWING then
        return "glowing " .. base
    end

    if cosmetic == cosmetics.RUNED then
        return "runed " .. base
    end

    if cosmetic == cosmetics.EMBROIDERED_SHINY and
        kind.class == classes.OBJ_ARMOUR then
        if embroidered[kind.id] then
            return "embroidered " .. base
        end

        if dyed[kind.id] then
            return "dyed " .. base
        end

        return "shiny " .. base
    end

    error("invalid cosmetic for " .. kind.id)
end

function properties.name(kind, ego, base)
    if ego == "" or ego == brands.NORMAL then
        return base
    end

    if kind.class == classes.OBJ_WEAPONS then
        local adjective = weapon_adjectives[ego]

        if adjective then
            return adjective .. " " .. base
        end

        local label = weapon_names[ego]

        if not label then
            error("unknown weapon brand name " .. ego)
        end

        return base .. " of " .. label
    end

    if kind.class == classes.OBJ_ARMOUR then
        local label = armour_names[ego]

        if not label then
            error("unknown armour ego name " .. ego)
        end

        return base .. " of " .. label
    end

    return base
end

return properties
