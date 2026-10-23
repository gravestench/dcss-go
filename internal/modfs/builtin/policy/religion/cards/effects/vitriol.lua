-- decks.cc:_damaging_card selects a glob at tier zero and corrosive bolts
-- above it. Tier two first corrodes visible threatening enemies at random.
local bolts = require("policy.magic.effects.zaps.bolts")
local enchant = require("policy.combat.monster_enchant")
local flags = require("constants.monster_flags")
local nearby = require("policy.religion.cards.effects.nearby")
local projectile = require("policy.magic.effects.zaps.projectile")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targeted = require("policy.religion.cards.effects.targeted")
local targets = require("policy.ai.targets")

local vitriol = {}

vitriol.uses_tier = true

local acid_splash = {
    name = "glob of acid",
    cap = 50,
    damage = {
        kind = "dicedef",
        count = 5,
        base = 4,
        numerator = 1,
        denominator = 3,
    },
    hit = {
        base = 7,
        numerator = 1,
        denominator = 6,
    },
    element = "MR_RES_ACID",
    after_hit = bolts.corrode,
}

local card_spell = {
    id = spells.SPELL_ACID_SPLASH,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
}

-- Source mons_is_threatening rejects explicit no-threat profiles before
-- the independent coinflip and equipment corrosion checks.
local function threatening(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- The entropy wave precedes aim even when the player later wastes the card.
-- Saved TARGET_CARD phase suppresses a duplicate wave on retry or restore.
local function entropy(ctx, player)
    ctx:emit("religion", "You radiate a wave of entropy!")

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        if targets.enemy(ctx, player, candidate.entity) and
            threatening(candidate.definition) and
            ctx:random(streams.CARDS, 2) == 0 then
            enchant.corrode_equipment(ctx, candidate.entity,
                candidate.definition, "The wave of entropy")
        end
    end
end

-- Both corrosive tiers use the same bolt; only tier two adds the wave.
function vitriol.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Vitriol requires a source power tier")
    end

    if tier == 2 and not request.target_phase then
        entropy(ctx, player)
    end

    local dx, dy, prompt = targeted.aim(ctx, player, request,
        "Vitriol")

    if prompt then
        return prompt
    end

    local spec = tier == 0 and acid_splash or
        projectile.specs[spells.SPELL_CORROSIVE_BOLT]

    projectile.fire(ctx, player, { dx = dx, dy = dy },
        card_spell, spec, targeted.zap_power(request))
end

return vitriol
