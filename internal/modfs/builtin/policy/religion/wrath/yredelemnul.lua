-- Yredelemnul sends permanent hostile servants from religion.cc's ordered
-- roster. Soul reclaim, zombie bases, and god-avatar spells need owners.
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local yredelemnul = {}

-- religion.cc:_yred_servants is ordered by power. The source clamps the
-- upper index after computing its lower index from the unclamped value.
local servants = {
    monsters.MONS_WIGHT,
    monsters.MONS_NECROPHAGE,
    monsters.MONS_SHADOW,
    monsters.MONS_PHANTOM,
    monsters.MONS_WRAITH,
    monsters.MONS_FLYING_SKULL,
    monsters.MONS_FREEZING_WRAITH,
    monsters.MONS_VAMPIRE,
    monsters.MONS_SHADOW_WRAITH,
    monsters.MONS_PHANTASMAL_WARRIOR,
    monsters.MONS_BOG_BODY,
    monsters.MONS_SKELETAL_WARRIOR,
    monsters.MONS_JIANGSHI,
    monsters.MONS_FLAYED_GHOST,
    monsters.MONS_VAMPIRE_KNIGHT,
    monsters.MONS_EIDOLON,
    monsters.MONS_DEATH_COB,
    monsters.MONS_ANCIENT_CHAMPION,
    monsters.MONS_GHOUL,
    monsters.MONS_REVENANT,
    monsters.MONS_SEARING_WRETCH,
    monsters.MONS_PROFANE_SERVITOR,
    monsters.MONS_BONE_DRAGON,
}

-- random2avg(n, 2) averages two draws before the summon attempt count.
-- Preserve the two draws even when n is one to keep source order visible.
local function attempts(ctx, level)
    local bound = 1 + math.floor(level / 5)
    local first = ctx:random(streams.CARDS, bound)
    local second = ctx:random(streams.CARDS, bound)

    return 1 + math.floor((first + second) / 2)
end

-- The hostile servant threshold grows with XL; selected kind and placement
-- use separate draws and the common summon owner writes the permanent body.
local function send_servant(ctx, player, level)
    local upper = 3 + math.floor((#servants - 3) * level / 21)
    local lower = upper <= 6 and 0 or math.floor(upper / 2) + 3
    upper = math.min(upper, #servants - 1)

    local index = lower + ctx:random(streams.CARDS,
        upper - lower + 1)

    return summons.hostile(ctx, player, gods.YREDELEMNUL,
        servants[index + 1]) ~= nil
end

-- Source checks follower reclaim only on the servant half of the coinflip.
-- A failed servant placement retries that attempt; zombie selection cannot
-- be approximated without the source's depth-specific zombifiable pool.
function yredelemnul.apply(ctx, player)
    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    if ctx:random(streams.CARDS, 2) ~= 0 then
        error("unimplemented Yredelemnul avatar draining wrath")
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship.god_id == gods.YREDELEMNUL and
        ctx:random(streams.CARDS, 2) == 0 then
        error("unimplemented Yredelemnul soul reclaim wrath")
    end

    local remaining = attempts(ctx, level)
    local count = 0

    while remaining > 0 do
        if ctx:random(streams.CARDS, level) == 0 then
            error("unimplemented Yredelemnul zombified hostile wrath")
        end

        if send_servant(ctx, player, level) then
            count = count + 1
            remaining = remaining - 1
        end
    end

    ctx:emit("religion", count > 1 and
        "Yredelemnul sends servants to punish you." or
        count == 1 and "Yredelemnul sends a servant to punish you." or
        "Yredelemnul's servants fail to arrive.")

    return true
end

return yredelemnul
