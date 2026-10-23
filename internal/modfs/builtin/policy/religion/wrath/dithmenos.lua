-- Dithmenos sends hostile shadows or uses saved sleep and sentinel marks.
-- Depth-specific random mobile summons need a separate population owner.
local channels = require("constants.message_channels")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local branches = require("ids.branches")
local component = require("constants.component")
local gods = require("constants.gods")
local flags = require("constants.monster_flags")
local mark = require("policy.traps.mark")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local sleep = require("policy.combat.monster_beams.sleep")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local sentinels = require("constants.population_sentinels")

local dithmenos = {}

-- The source RANDOM_MOBILE_MONSTER veto excludes stationary monsters
-- after selecting the Dungeon's XL+5 depth. Stable catalog IDs ensure
-- adding an unrelated mod file cannot reorder this weighted pool.
local function mobile_roster()
    local allowed = {}

    for _, definition in ipairs(catalog.all(categories.MONSTERS)) do
        local mobile = true

        for _, flag in ipairs(definition.flags or {}) do
            if flag == flags.STATIONARY then
                mobile = false
                break
            end
        end

        if mobile then
            allowed[definition.id] = true
        end
    end

    return allowed
end

-- Source div_rand_round draws only when the division has a remainder;
-- this sets both the army size and the shadow tier without extra rolls.
local function rounded(ctx, numerator, divisor)
    local whole = math.floor(numerator / divisor)
    local remainder = numerator % divisor

    if remainder == 0 then
        return whole
    end

    return whole + (ctx:random(streams.CARDS, divisor) < remainder and 1 or 0)
end

-- random2avg uses one exclusive draw, then inclusive draws before
-- dividing the sum. A zero bound contributes zero without host RNG.
local function average(ctx, bound, count)
    -- random2(0) and random2(1) both return zero in the source.
    if bound <= 0 then
        return 0
    end

    local total = bound == 1 and 0 or
        ctx:random(streams.CARDS, bound)

    for _ = 2, count do
        total = total + ctx:random(streams.CARDS, bound + 1)
    end

    return math.floor(total / count)
end

-- Each attempted monster can change the next tier choice only when its
-- placement succeeds. Count source bodies rather than attempts.
local function send_shadows(ctx, player, level)
    local attempts = 3 + average(ctx, rounded(ctx, level, 3), 2)
    local tier = rounded(ctx, level, 9)
    local created = 0

    for _ = 1, attempts do
        local kind = monsters.MONS_SHADOW

        if tier >= 2 and created == 0 and
            ctx:random(streams.CARDS, 2) == 0 then
            kind = monsters.MONS_TZITZIMITL
        elseif tier >= 1 and created < 3 and
            ctx:random(streams.CARDS, 2) == 0 then
            kind = monsters.MONS_SHADOW_DEMON
        end

        if summons.hostile(ctx, player, gods.DITHMENOS, kind) then
            created = created + 1
        end
    end

    ctx:emit(channels.RELIGION, created > 0 and
        "Dithmenos calls forth shadows to punish you." or
        "Dithmenos fails to incite the shadows against you.")
end

-- Dithmenos's second slot borrows Dungeon population at the player's
-- XL+5 and applies source degree-four expiry. A NO_MONSTER row or blocked
-- adjacent placement still consumes that attempt without substituting.
local function send_mobile(ctx, player, level)
    local count = 2 + average(ctx, rounded(ctx, level, 4), 4)
    local depth = math.min(27, level + 5)
    local choices, total = pool.at_depth(branches.BRANCH_DUNGEON,
        depth, mobile_roster())
    local created = 0

    for _ = 1, count do
        local kind = pool.pick(ctx, choices, total, streams.CARDS)

        if kind ~= sentinels.NO_MONSTER and
            summons.hostile(ctx, player, gods.DITHMENOS,
                kind, 4, depth) then
            created = created + 1
        end
    end

    ctx:emit(channels.RELIGION, created > 0 and
        "Dithmenos weaves monsters from the shadows." or
        "Dithmenos fails to weave monsters from the shadows.")
end

-- Four equally likely source slots choose shadows, depth-based mobile
-- creatures, sleep, or an alarm mark.
function dithmenos.apply(ctx, player)
    local choice = ctx:random(streams.CARDS, 4)

    if choice == 0 then
        local level = ctx:get(player, component.PROGRESSION).level

        send_shadows(ctx, player, level)
    elseif choice == 1 then
        local level = ctx:get(player, component.PROGRESSION).level

        send_mobile(ctx, player, level)
    elseif choice == 2 then
        ctx:emit(channels.RELIGION,
            "Dithmenos says: You feel overwhelmed by the shadows around you.")
        sleep.apply_unresisted(ctx, player,
            30 + ctx:random(streams.CARDS, 20))
    else
        ctx:emit(channels.RELIGION,
            "Dithmenos tears the shadows away from you.")
        mark.apply(ctx, player, streams.CARDS)
    end

    return true
end

return dithmenos
