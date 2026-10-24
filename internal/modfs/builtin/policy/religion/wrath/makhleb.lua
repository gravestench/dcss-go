-- Makhleb chooses between a god-cast destruction spell and hostile demon
-- servants. Both routes carry Makhleb as their damage or summon source.
local component = require("constants.component")
local gods = require("constants.gods")
local roster = require("policy.religion.makhleb.roster")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local avatar = require("policy.religion.wrath.avatar")

local makhleb = {}

-- random_choose draws uniformly in source order. Every creature receives
-- Makhleb's god source even though the player is the placement anchor.
local greater_kinds = roster.greater
local lesser_kinds = roster.lesser

-- The three source destruction tiers grow with XL. Each registered spell
-- owns its beam, resistance, cloud, or lasting-status effect in Lua.
local destruction_spells = {
    {
        spells.SPELL_THROW_FLAME,
        spells.SPELL_PAIN,
        spells.SPELL_STONE_ARROW,
        spells.SPELL_SHOCK,
        spells.SPELL_SPIT_ACID,
    },
    {
        spells.SPELL_BOLT_OF_FIRE,
        spells.SPELL_FIREBALL,
        spells.SPELL_LIGHTNING_BOLT,
        spells.SPELL_STICKY_FLAME,
        spells.SPELL_IRON_SHOT,
        spells.SPELL_BOLT_OF_DRAINING,
        spells.SPELL_ORB_OF_ELECTRICITY,
    },
    {
        spells.SPELL_FIREBALL,
        spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
        spells.SPELL_ORB_OF_ELECTRICITY,
        spells.SPELL_FLASH_FREEZE,
        spells.SPELL_GHOSTLY_FIREBALL,
    },
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

-- Source random_range is inclusive. Clamp only after the range draw, then
-- choose one spell uniformly from that tier before the avatar fires.
local function destruction(ctx, player, level)
    if not avatar.available(ctx, player, gods.MAKHLEB) then
        return false
    end

    local minimum = math.floor(level / 14)
    local maximum = math.floor(level / 9)
    local severity = math.min(2, minimum +
        roll(ctx, maximum - minimum + 1))
    local choices = destruction_spells[severity + 1]
    local spell_id = choices[ctx:random(streams.CARDS,
        #choices) + 1]

    return avatar.cast(ctx, player, gods.MAKHLEB, spell_id)
end

-- Coinflip selects destruction or hostile servants before either branch
-- draws severity. Both branches use the same saved god source and credit.
function makhleb.apply(ctx, player)
    local progression = ctx:get(player, component.PROGRESSION)
    local level = math.max(1, progression.level)

    if ctx:random(streams.CARDS, 2) == 0 then
        return destruction(ctx, player, level)
    end

    return send_servants(ctx, player, level)
end

return makhleb
