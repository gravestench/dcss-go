-- decks.cc:_wild_magic_card independently tests every visible threatening
-- enemy, gives each success one destructive miscast, then restores MP.
local component = require("constants.component")
local flags = require("constants.monster_flags")
local miscast = require("policy.magic.miscast")
local monster_stats = require("policy.combat.monster_stats")
local nearby = require("policy.religion.cards.effects.nearby")
local schools = require("constants.spell_schools")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local wild_magic = {}

wild_magic.uses_tier = true

local destructive_schools = {
    schools.CONJURATION,
    schools.FIRE,
    schools.ICE,
    schools.EARTH,
    schools.AIR,
    schools.POISON,
    schools.TRANSMUTATION,
    schools.HEXES,
    schools.NECROMANCY,
}

-- mons_is_threatening rejects no-threat bodies before consuming either
-- the chance or school draws for that monster.
local function threatening(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- A successful x_chance_in_y is certain above HD; the source still draws
-- its random2(5) bonus before that comparison for every eligible enemy.
local function affected(ctx, tier, hd)
    local numerator = (tier + 1) * 5 +
        ctx:random(streams.CARDS, 5)

    return numerator >= hd or
        ctx:random(streams.CARDS, hd) < numerator
end

-- Affected count, not actual HP damage or status success, determines the
-- number of independent random2(5) MP rolls after all miscasts resolve.
function wild_magic.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Wild Magic requires a source power tier")
    end

    local count = 0

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        if targets.enemy(ctx, player, candidate.entity) and
            threatening(candidate.definition) and
            affected(ctx, tier, monster_stats.hit_dice(ctx,
                candidate.entity, candidate.definition)) then
            local school = destructive_schools[
                ctx:random(streams.CARDS, #destructive_schools) + 1]
            local fail = ctx:random(streams.CARDS, 70)

            miscast.apply(ctx, candidate.entity, player, school,
                3 * (tier + 1), fail, streams.CARDS)
            count = count + 1
        end
    end

    if count == 0 then
        ctx:emit("religion", "Nothing happens.")

        return
    end

    local restored = 0

    for _ = 1, count do
        restored = restored + ctx:random(streams.CARDS, 5)
    end

    ctx:emit("religion", "You feel a surge of magic.")

    local magic = ctx:get(player, component.MAGIC)

    if not magic then
        error("Wild Magic player lacks magic resources")
    end

    if restored > 0 and magic.current < magic.max then
        magic.current = math.min(magic.max, magic.current + restored)
        ctx:set(player, component.MAGIC, magic)
        ctx:emit("religion", "You feel your power returning.")
    end
end

return wild_magic
