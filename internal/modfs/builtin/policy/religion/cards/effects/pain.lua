-- decks.cc:_damaging_card uses Agony at tier zero, a draining bolt above
-- it, and a self-centered Torment before aim at tier two.
local agony = require("policy.magic.effects.zaps.agony")
local area = require("policy.combat.torment_area")
local drain = require("policy.combat.monster_drain")
local projectile = require("policy.magic.effects.zaps.projectile")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targeted = require("policy.religion.cards.effects.targeted")

local pain = {}

pain.uses_tier = true

local card_spell = {
    id = spells.SPELL_BOLT_OF_DRAINING,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
}

-- beam.cc:BEAM_NEG drains a surviving susceptible monster after its
-- resistible bolt damage. The ordinary drain owner stores the timed HD loss.
local function drain_after_hit(ctx, player, monster, definition)
    drain.apply(ctx, monster, definition, player, streams.SPELL, true)
end

local draining_bolt = {
    name = "bolt of negative energy",
    cap = 200,
    beam = true,
    damage = {
        kind = "calcdice",
        count = 4,
        base = 15,
        numerator = 3,
        denominator = 5,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 20,
    },
    element = "MR_RES_NEG",
    after_hit = drain_after_hit,
}

-- Agony's ordinary spell range is one, but a card zap is LOS long.
-- Its shared willpower and Torment rules receive the card's fixed reach.
local agony_spell = {
    id = spells.SPELL_AGONY,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
}

-- The high-tier symbol happens before targeting and survives an abort.
-- TARGET_CARD on resume means it already occurred before the saved prompt.
function pain.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Pain requires a source power tier")
    end

    if tier == 2 and not request.target_phase then
        ctx:emit("religion", "You reveal a symbol of torment!")
        area.apply(ctx, player, "religion")
    end

    local dx, dy, prompt = targeted.aim(ctx, player, request,
        "Pain")

    if prompt then
        return prompt
    end

    local intent = { dx = dx, dy = dy }
    local power = targeted.zap_power(request)

    if tier == 0 then
        agony.resolve(ctx, player, intent, agony_spell, power)
    else
        projectile.fire(ctx, player, intent, card_spell,
            draining_bolt, power)
    end
end

return pain
