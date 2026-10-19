-- Monster corruption draws Abyss:1 population with the source exclusion
-- predicate: no Abyss-only species and no holy creature.
local catalog = require("policy.catalog")
local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")
local rows = require("policy.combat.monster_corruption_abyss_rows")

local servants = {}
local abyss_only = {
    MONS_ANCIENT_ZYME = true,
    MONS_ELDRITCH_TENTACLE = true,
    MONS_ELDRITCH_TENTACLE_SEGMENT = true,
    MONS_LURKING_HORROR = true,
    MONS_WRETCHED_STAR = true,
}

local function holy(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == "MH_HOLY" then
            return true
        end
    end

    return false
end

-- The population curve is evaluated at branch depth one. Keeping source
-- rows in order gives the same first eligible monster for a zero draw.
local function weight_at_one(row)
    local min_depth = row[1]
    local max_depth = row[2]
    local rarity = row[3] * 2520
    local curve = row[4]
    local span = max_depth - min_depth

    if curve == "FLAT" then
        return rarity
    end

    if curve == "SEMI" then
        span = span == 0 and 2 or span * 2

        return math.floor(rarity *
            (span - math.abs(min_depth + max_depth - 2)) / span)
    end

    if curve == "PEAK" then
        span = span + 2

        return math.floor(rarity *
            (span - math.abs(min_depth + max_depth - 2)) / span)
    end

    if curve == "RISE" then
        return math.floor(rarity * (2 - min_depth) / (span + 1))
    end

    if curve == "FALL" then
        return math.floor(rarity * (max_depth - 1 + 1) / (span + 1))
    end

    error("unsupported Abyss population curve " .. tostring(curve))
end

local function eligible_rows()
    local entries = {}

    for _, row in ipairs(rows) do
        local id = monsters[row[5]]

        if id and not abyss_only[id] then
            local definition = catalog.get("monsters", id)
            local weight = weight_at_one(row)

            if weight > 0 and not holy(definition) then
                entries[#entries + 1] = {
                    id = id,
                    weight = weight,
                }
            end
        end
    end

    return entries
end

function servants.pick(ctx)
    return choice.weighted(ctx, eligible_rows())
end

return servants
