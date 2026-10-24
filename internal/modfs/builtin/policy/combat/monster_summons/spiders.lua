-- Summon Spiders and Broodmother's wound birth use the same source
-- `summon_spider` species weights. Their counts, anchors, and provenance
-- remain with the spell and bite owners respectively.
local choice = require("policy.combat.monster_summons.choice")
local monsters = require("ids.monsters")

local spiders = {}

local roster = {
    [monsters.MONS_REDBACK] = true,
    [monsters.MONS_JUMPING_SPIDER] = true,
    [monsters.MONS_TARANTELLA] = true,
    [monsters.MONS_CULICIVORA] = true,
    [monsters.MONS_ORB_SPIDER] = true,
    [monsters.MONS_WOLF_SPIDER] = true,
}

-- Build weights per call because Wolf Spider weight is half of current
-- power. A zero-power source omits that species instead of drawing zero.
local function pool(power)
    local entries = {
        {
            id = monsters.MONS_REDBACK,
            weight = 100,
        },
        {
            id = monsters.MONS_JUMPING_SPIDER,
            weight = 100,
        },
        {
            id = monsters.MONS_TARANTELLA,
            weight = 75,
        },
        {
            id = monsters.MONS_CULICIVORA,
            weight = 50,
        },
        {
            id = monsters.MONS_ORB_SPIDER,
            weight = 50,
        },
    }
    local wolf_weight = math.floor(power / 2)

    if wolf_weight > 0 then
        entries[#entries + 1] = {
            id = monsters.MONS_WOLF_SPIDER,
            weight = wolf_weight,
        }
    end

    return entries
end

-- Both call sites select from this same ordered roster on the summon
-- stream, so a later source weight correction updates both behaviours.
function spiders.pick(ctx, power)
    return choice.weighted(ctx, pool(power))
end

-- Save validation needs the same roster identity that the picker emits.
function spiders.contains(kind_id)
    return roster[kind_id] == true
end

return spiders
