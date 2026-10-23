-- Makhleb's servant punishment uses the ordinary saved hostile summon
-- owner. Spell destruction requires a god avatar and remains explicit.
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local makhleb = {}

-- random_choose draws uniformly in source order. Every creature receives
-- Makhleb's god source even though the player is the placement anchor.
local greater_kinds = {
    monsters.MONS_EXECUTIONER,
    monsters.MONS_GREEN_DEATH,
    monsters.MONS_BLIZZARD_DEMON,
    monsters.MONS_BALRUG,
    monsters.MONS_CACODEMON,
}

local lesser_kinds = {
    monsters.MONS_HELLWING,
    monsters.MONS_NEQOXEC,
    monsters.MONS_ORANGE_DEMON,
    monsters.MONS_SMOKE_DEMON,
    monsters.MONS_YNOXINUL,
}

-- Source random2 returns zero for bounds of zero or one without consuming a
-- meaningful choice. Avoid asking the host RNG for an invalid zero bound.
local function roll(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(streams.CARDS, bound)
end

-- god-wrath.cc:_makhleb_num_greater_servants makes severity scale with XL;
-- one-in-five suppression only applies to its middle severity band.
local function greater_count(ctx, level)
    local severity = 1 + math.floor(level / 2) +
        roll(ctx, math.floor(level / 2))

    if severity > 13 then
        return 2 + roll(ctx, math.floor((level - 2) / 5))
    end

    if severity > 7 and ctx:random(streams.CARDS, 5) ~= 0 then
        return 1
    end

    return 0
end

-- Count attempted servants before placement, as blocked cells can reduce
-- the arriving army without changing its source selection or RNG order.
local function send_servants(ctx, player, level)
    local greater = greater_count(ctx, level)
    local total = math.max(greater, 1 + math.floor(
        (roll(ctx, level) + roll(ctx, level)) / 10))
    local created = 0

    for _ = 1, greater do
        local kind = greater_kinds[ctx:random(streams.CARDS,
            #greater_kinds) + 1]

        if summons.hostile(ctx, player, gods.MAKHLEB, kind) then
            created = created + 1
        end
    end

    for _ = 1, total - greater do
        local kind = lesser_kinds[ctx:random(streams.CARDS,
            #lesser_kinds) + 1]

        if summons.hostile(ctx, player, gods.MAKHLEB, kind) then
            created = created + 1
        end
    end

    ctx:emit("religion", created > 1 and
        "Makhleb sends minions to punish you." or
        created == 1 and "Makhleb sends a minion to punish you." or
        "Makhleb's minions fail to arrive.")

    return true
end

-- Half of Makhleb's retributions use destructive god-avatar spells. That
-- spell path has no saved avatar caster yet, so its draw cannot be replaced
-- with direct HP loss while preserving spell, resistance, and attribution.
function makhleb.apply(ctx, player)
    if ctx:random(streams.CARDS, 2) == 0 then
        error("unimplemented Makhleb destruction wrath")
    end

    local progression = ctx:get(player, component.PROGRESSION)

    return send_servants(ctx, player, math.max(1, progression.level))
end

return makhleb
