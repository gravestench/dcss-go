-- Source: crawl-ref/source/skill-type.h. This order determines Gnoll XP
-- spending order; mod-added skills follow the pinned skills by ID.
local skills = require("ids.skills")
local catalog = require("policy.catalog")

local order = {}

local pinned = {
    skills.SK_FIGHTING,
    skills.SK_SHORT_BLADES,
    skills.SK_LONG_BLADES,
    skills.SK_AXES,
    skills.SK_MACES_FLAILS,
    skills.SK_POLEARMS,
    skills.SK_STAVES,
    skills.SK_RANGED_WEAPONS,
    skills.SK_THROWING,
    skills.SK_ARMOUR,
    skills.SK_DODGING,
    skills.SK_STEALTH,
    skills.SK_SHIELDS,
    skills.SK_UNARMED_COMBAT,
    skills.SK_SPELLCASTING,
    skills.SK_CONJURATIONS,
    skills.SK_HEXES,
    skills.SK_SUMMONINGS,
    skills.SK_NECROMANCY,
    skills.SK_TRANSLOCATIONS,
    skills.SK_TRANSMUTATIONS,
    skills.SK_FIRE_MAGIC,
    skills.SK_ICE_MAGIC,
    skills.SK_AIR_MAGIC,
    skills.SK_EARTH_MAGIC,
    skills.SK_POISON_MAGIC,
    skills.SK_INVOCATIONS,
    skills.SK_EVOCATIONS,
}

function order.all()
    local result = {}
    local seen = {}

    for _, id in ipairs(pinned) do
        result[#result + 1] = id
        seen[id] = true
    end

    local added = {}

    for _, species in ipairs(catalog.all("species")) do
        if species.selectable then
            for id, aptitude in pairs(species.aptitudes or {}) do
                if aptitude.allowed and not seen[id] then
                    added[#added + 1] = id
                    seen[id] = true
                end
            end
        end
    end

    table.sort(added)

    for _, id in ipairs(added) do
        result[#result + 1] = id
    end

    return result
end

return order
