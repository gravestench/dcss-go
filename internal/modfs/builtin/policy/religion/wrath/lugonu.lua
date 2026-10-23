-- Lugonu first distorts the player's location, then calls Abyssal minions.
-- The two phases retain their independent source draws and placement.
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local lugonu = {}

-- Source random2 returns zero without touching the host RNG for bounds
-- zero or one. This matters for a low-level major servant count.
local function draw(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(streams.CARDS, bound)
end

-- The source's variadic random_choose_weighted uses reservoir selection:
-- every later candidate gets a new roll against the running weight.
local function minor_kind(ctx, level)
    local weights = {
        15 - math.floor(level / 2),
        math.floor(level / 2),
        6,
        3,
    }
    local kinds = {
        monsters.MONS_ABOMINATION_SMALL,
        monsters.MONS_ABOMINATION_LARGE,
        monsters.MONS_THRASHING_HORROR,
        monsters.MONS_ANCIENT_ZYME,
    }
    local choice = kinds[1]
    local total = weights[1]

    for index = 2, #weights do
        total = total + weights[index]

        if draw(ctx, total) < weights[index] then
            choice = kinds[index]
        end
    end

    return choice
end

-- Source chooses major status before count. A major send can include zero
-- lesser minions, but always attempts one of three high-tier horrors.
local function send_minions(ctx, player)
    local level = ctx:get(player, component.PROGRESSION).level
    local major = level > 4 + draw(ctx, 12)

    if major then
        major = draw(ctx, 5) ~= 0
    end

    local count

    if major then
        count = draw(ctx, math.floor(level / 9) + 1)
    else
        count = math.max(draw(ctx, 3) + math.floor(level / 7), 1)
    end

    local created = false

    for _ = 1, count do
        local kind = minor_kind(ctx, level)

        if summons.hostile(ctx, player, gods.LUGONU, kind) then
            created = true
        end
    end

    if major then
        local horrors = {
            monsters.MONS_TENTACLED_STARSPAWN,
            monsters.MONS_WRETCHED_STAR,
            monsters.MONS_STARCURSED_MASS,
        }
        local kind = horrors[draw(ctx, #horrors) + 1]

        if summons.hostile(ctx, player, gods.LUGONU, kind) then
            created = true
        end
    end

    ctx:emit(channels.RELIGION, created and
        "Lugonu sends minions to punish you." or
        "Lugonu's minions fail to arrive.")
end

-- Forced teleport favors embarrassing landings near monsters and forced
-- banishment chooses a level-scaled Abyss entry. The generic owners do
-- not yet expose these source options, so reject those draws explicitly.
local function translocate(ctx)
    if draw(ctx, 2) ~= 0 then
        error("unimplemented Lugonu monster-near forced teleport wrath")
    end

    if draw(ctx, 2) ~= 0 then
        error("unimplemented Lugonu level-scaled forced banishment wrath")
    end
end

-- The no-translocation quarter still receives minions and the normal
-- penance/bonus handling in retribution.invoke_god.
function lugonu.apply(ctx, player)
    translocate(ctx)
    send_minions(ctx, player)

    return true
end

return lugonu
