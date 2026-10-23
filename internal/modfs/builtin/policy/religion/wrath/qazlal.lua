-- Qazlal's thunder precedes either elemental servants or temporary
-- vulnerability. Servants use the shared population and god-summon owners.
local component = require("constants.component")
local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local curves = require("constants.population_curves")
local gods = require("constants.gods")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local god_gift = require("policy.mutations.god_gift")
local noise = require("policy.world.noise")
local pool = require("policy.population.pool")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local qazlal = {}

-- Build named population rows so the source's five fields retain their
-- intended depth, curve, and monster meaning in the shared picker.
local function servant(first, last, rarity, curve, kind)
    return {
        min_depth = first,
        max_depth = last,
        rarity = rarity,
        curve = curve,
        monster_id = kind,
    }
end

-- god-wrath.cc:pop_qazlal_wrath retains source order and duplicate curves.
local rows = {
    servant(0, 12, 25, curves.SEMI, monsters.MONS_AIR_ELEMENTAL),
    servant(4, 12, 50, curves.FLAT, monsters.MONS_WIND_DRAKE),
    servant(10, 22, 50, curves.SEMI, monsters.MONS_SPARK_WASP),
    servant(18, 27, 50, curves.RISE, monsters.MONS_STORM_DRAGON),

    servant(0, 12, 25, curves.SEMI, monsters.MONS_FIRE_ELEMENTAL),
    servant(4, 12, 50, curves.FLAT, monsters.MONS_FIRE_CRAB),
    servant(8, 16, 30, curves.FLAT, monsters.MONS_LINDWURM),
    servant(12, 27, 50, curves.SEMI, monsters.MONS_FIRE_DRAGON),

    servant(0, 12, 25, curves.SEMI, monsters.MONS_WATER_ELEMENTAL),
    servant(2, 10, 50, curves.FLAT, monsters.MONS_RIME_DRAKE),
    servant(12, 27, 50, curves.SEMI, monsters.MONS_ICE_DRAGON),
    servant(20, 27, 30, curves.RISE, monsters.MONS_SHARD_SHRIKE),

    servant(0, 12, 25, curves.SEMI, monsters.MONS_EARTH_ELEMENTAL),
    servant(2, 10, 50, curves.FLAT, monsters.MONS_BASILISK),
    servant(4, 14, 30, curves.FLAT, monsters.MONS_BOULDER_BEETLE),
    servant(18, 27, 50, curves.RISE, monsters.MONS_IRON_DRAGON),
}

-- Attempt the source's rounded level/7 count even if placement fails;
-- selection and placement each consume their own ordered card draws.
local function summon_elementals(ctx, player, level)
    local count = 1 + math.floor(level / 7)

    -- Source div_rand_round spends this roll only for a nonzero remainder.
    if level % 7 ~= 0 and
        ctx:random(streams.CARDS, 7) < level % 7 then
        count = count + 1
    end

    local choices, total = pool.at_rows(rows, level)
    local created = false

    for _ = 1, count do
        local kind = pool.pick(ctx, choices, total, streams.CARDS)

        if summons.hostile(ctx, player, gods.QAZLAL, kind) then
            created = true
        end
    end

    ctx:emit(channels.RELIGION, created and
        "Qazlal incites the elements against you!" or
        "Qazlal fails to incite the elements against you.")
end

-- Source: god-wrath.cc:_qazlal_elemental_vulnerability announces success
-- for mutation, conflict trade, or unsafe-body decomposition. All other
-- results use the failed message after the mutation owner's ordered draws.
local function elemental_vulnerability(ctx, player)
    local result = god_gift.grant_random(ctx, player, choices.QAZLAL,
        classes.TEMPORARY)
    local success = result.kind == "granted" or
        result.kind == "traded" or result.kind == "decomposed"

    ctx:emit(channels.RELIGION, success and
        "Qazlal strips away your elemental protection." or
        "Qazlal fails to strip away your elemental protection.")
end

-- Source coinflip is bool(random2(2)): a one emits thunder and a one
-- summons servants. The zero second draw takes the mutation branch.
function qazlal.apply(ctx, player)
    if ctx:random(streams.CARDS, 2) ~= 0 then
        ctx:emit(channels.RELIGION,
            "Qazlal causes a mighty clap of thunder!")
        noise.emit(ctx, ctx:get(player, component.POSITION), 25, player)
    end

    if ctx:random(streams.CARDS, 2) == 0 then
        elemental_vulnerability(ctx, player)

        return true
    end

    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    summon_elementals(ctx, player, level)

    return true
end

return qazlal
