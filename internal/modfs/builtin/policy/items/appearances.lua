local source = require("data.item_appearances")
local classes = require("ids.object_classes")
local pools = require("constants.appearance_pools")

local appearances = {}
local syllables = {
    "A", "BE", "CO", "DU", "FA", "GI", "HU", "IR",
    "JO", "KA", "LU", "MU", "NE", "OX", "PU", "QI",
    "RA", "SE", "TO", "UL", "VO", "WE", "XI", "YO",
    "ZA",
}

-- Honor an explicit pool first, then use item class so unidentified descriptors stay in the right family.
-- Example: appearances.pool(potion_kind) maps an unidentified potion to the potion descriptor pool.
function appearances.pool(kind)
    if kind.identification_pool then
        return kind.identification_pool
    end

    if kind.class == classes.OBJ_WANDS then
        return pools.WAND
    end

    if kind.class == classes.OBJ_POTIONS then
        return pools.POTION
    end

    if kind.class == classes.OBJ_SCROLLS then
        return pools.SCROLL
    end

    if kind.class == classes.OBJ_STAVES then
        return pools.STAFF
    end

    if kind.class == classes.OBJ_JEWELLERY then
        if kind.id:match("^AMU_") then
            return pools.AMULET
        end

        if kind.id:match("^RING_") then
            return pools.RING
        end

        error("jewellery " .. kind.id ..
            " needs an explicit identification_pool")
    end

    return nil
end

-- Source: ng-init.cc. A plain descriptor has one uniform
-- chance plus the source's extra 50% plain-description chance.
function appearances.weight(pool, seed)
    if pool == pools.SCROLL or pool == pools.STAFF then
        return 1
    end

    local descriptors = source[pool]
    local primary = descriptors.primary
    local secondary = descriptors.secondary

    if pool == pools.POTION then
        primary = descriptors.colours
        secondary = descriptors.qualifiers
    end

    if seed < #primary then
        return #secondary + 1
    end

    return 1
end

-- Separate plain descriptors from qualified ones for weighted appearance assignment.
function appearances.primary_count(pool)
    local descriptors = source[pool]

    if not descriptors then
        error("unknown item appearance pool " .. tostring(pool))
    end

    if pool == pools.POTION then
        return #descriptors.colours
    end

    return #descriptors.primary
end

-- Use each pool's real combinations so assignment never runs past available appearances.
function appearances.capacity(pool)
    if pool == pools.SCROLL then
        return 151 * 151
    end

    local descriptors = source[pool]

    if not descriptors then
        error("unknown item appearance pool " .. tostring(pool))
    end

    if pool == pools.POTION then
        return #descriptors.colours * #descriptors.qualifiers
    end

    return #descriptors.primary * #descriptors.secondary
end

-- Source: item-name.cc. The higher seed values enable
-- secondary adjectives or potion qualifiers. Scroll labels still need
-- the exact make_name generator from item-name.cc.
function appearances.name(pool, seed)
    local capacity = appearances.capacity(pool)

    if seed < 0 or seed >= capacity or seed ~= math.floor(seed) then
        error("invalid " .. pool .. " appearance seed " .. tostring(seed))
    end

    if pool == pools.SCROLL then
        local label = ""

        for _ = 1, 4 do
            label = syllables[seed % #syllables + 1] .. label
            seed = math.floor(seed / #syllables)
        end

        return "scroll labelled " .. label
    end

    local descriptors = source[pool]
    local primary = descriptors.primary
    local secondary = descriptors.secondary

    if pool == pools.POTION then
        primary = descriptors.colours
        secondary = descriptors.qualifiers
    end

    local noun = pool
    local first = primary[seed % #primary + 1]
    local second = secondary[math.floor(seed / #primary) + 1]

    if first:sub(-1) ~= " " then
        first = first .. " "
    end

    return second .. first .. noun
end

return appearances
