local classes = require("ids.object_classes")
local items = require("ids.items")
local gods = require("constants.gods")
local god_names = require("constants.randart_name_gods")
local brands = require("constants.weapon_brands")
local egos = require("constants.armour_egos")
local properties = require("ids.artefact_properties")
local xom_epithets = require("data.xom_name_epithets")

local name_gods = {}

-- A random artefact may mention a god without having been gifted by one.
-- Source artefact naming tests that mention against the finished item's type,
-- brand, and properties. Keep these restrictions here so name phrases and
-- divine gift generation can eventually share the same rule.
local evil = {
    [gods.KIKUBAAQUDGHA] = true,
    [gods.MAKHLEB] = true,
    [gods.YREDELEMNUL] = true,
    [gods.BEOGH] = true,
    [gods.LUGONU] = true,
    [gods.DITHMENOS] = true,
}

local good = {
    [gods.ZIN] = true,
    [gods.SHINING_ONE] = true,
    [gods.ELYVILON] = true,
}

local anti_good_brands = {
    [brands.DRAINING] = true,
    [brands.PAIN] = true,
    [brands.VAMPIRISM] = true,
    [brands.REAPING] = true,
    [brands.CHAOS] = true,
}

local demonic_weapons = {
    [items.WPN_DEMON_BLADE] = true,
    [items.WPN_DEMON_WHIP] = true,
    [items.WPN_DEMON_TRIDENT] = true,
}

local trog_brands = {
    [brands.VORPAL] = true,
    [brands.FLAMING] = true,
    [brands.ANTIMAGIC] = true,
}

-- The source's god_likes_item_type rejects these combinations before
-- considering the rolled artefact properties.
local function likes_item_type(id, definition)
    if definition.class == classes.OBJ_WEAPONS then
        return id ~= gods.ELYVILON and id ~= gods.SIF_MUNA and
            id ~= gods.VEHUMET
    end

    return id ~= gods.TROG
end

-- Name eligibility mirrors artefact.cc:_god_fits_artefact with its
-- name_check_only path. Property maps are keyed by shared artefact IDs.
function name_gods.eligible(id, definition, brand, rolled)
    rolled = rolled or {}

    if id == gods.NO_GOD or id == gods.JIYVA or
        not likes_item_type(id, definition) then
        return false
    end

    if evil[id] and brand == brands.HOLY_WRATH then
        return false
    end

    if good[id] and
        (anti_good_brands[brand] or demonic_weapons[definition.id]) then
        return false
    end

    if id == gods.ZIN then
        return not rolled[properties.CONTAM] or
            rolled[properties.CONTAM] == 0
    end

    if id == gods.SHINING_ONE then
        return (definition.class ~= classes.OBJ_WEAPONS or
            brand == brands.HOLY_WRATH) and
            (rolled[properties.INVISIBLE] or 0) == 0 and
            (rolled[properties.STEALTH] or 0) <= 0
    end

    if id == gods.LUGONU then
        return definition.class ~= classes.OBJ_WEAPONS or
            brand == brands.DISTORTION
    end

    if id == gods.KIKUBAAQUDGHA and
        definition.class == classes.OBJ_WEAPONS and
        brand ~= brands.PAIN then
        return false
    end

    if id == gods.KIKUBAAQUDGHA or id == gods.SIF_MUNA or
        id == gods.VEHUMET then
        return (rolled[properties.PREVENT_SPELLCASTING] or 0) == 0
    end

    if id == gods.TROG then
        return trog_brands[brand] and
            (rolled[properties.MAGICAL_POWER] or 0) <= 0 and
            (rolled[properties.INTELLIGENCE] or 0) <= 0
    end

    if id == gods.CHEIBRIADOS then
        return brand ~= brands.SPEED and brand ~= egos.RAMPAGING and
            (rolled[properties.ANGRY] or 0) == 0 and
            (rolled[properties.RAMPAGING] or 0) == 0
    end

    if id == gods.DITHMENOS then
        return (rolled[properties.STEALTH] or 0) >= 0
    end

    return true
end

-- Source retries a uniformly chosen god until one fits. Filtering first
-- gives each eligible god the same weight without an unbounded retry loop.
function name_gods.choose(random, definition, brand, rolled)
    local eligible = {}

    for _, entry in ipairs(god_names) do
        if name_gods.eligible(entry.id, definition, brand, rolled) then
            eligible[#eligible + 1] = entry.name
        end
    end

    if #eligible == 0 then
        error("no god can name this random artefact")
    end

    return eligible[random(#eligible) + 1]
end

-- Xom has a short name and a separately weighted long-name database.
-- The coinflip must happen first so a short name consumes no epithet draw.
function name_gods.xom_name(random)
    if random(2) ~= 0 then
        return "Xom"
    end

    local total = 0

    for _, entry in ipairs(xom_epithets) do
        total = total + entry.weight
    end

    local pick = random(total)

    for _, entry in ipairs(xom_epithets) do
        pick = pick - entry.weight

        if pick < 0 then
            return entry.text
        end
    end

    error("Xom name weights are empty")
end

return name_gods
