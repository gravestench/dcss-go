local statuses = require("policy.magic.effects.statuses.player")
local sanguine = require("policy.character.sanguine_armour")
local spirit_shield = require("policy.combat.spirit_shield")
local causes = require("constants.damage_causes")
local reactions = require("policy.combat.player_damage_reactions")
local jiyva_retaliation = require("policy.religion.jiyva.retaliation")
local curl = require("policy.character.curl")
local extra_lives = require("policy.character.extra_lives")
local petrification = require("policy.combat.player_petrification")
local sleep = require("policy.character.sleep")

local health_policy = {}

-- Religion owns its reaction logic; this shared health boundary only
-- installs it and passes through the real damage source after HP changes.
jiyva_retaliation.register()

-- All ordinary damage to the player passes through this rule. The source's
-- ouch.cc exception is reserved for explicitly fatal environmental causes.
function health_policy.damage(ctx, player, amount, fatal_exception, attacker,
    cause)
    local health = ctx:get(player, "core.health")

    if not health then
        error("player has no health")
    end

    amount = petrification.reduce_damage(ctx, player, amount)

    local dealt = statuses.death_door_damage(ctx, player, amount,
        fatal_exception or false)
    local damage_cause = cause or causes.HIT

    -- Source: ouch.cc wakes the player from ordinary nonfatal damage.
    if dealt > 0 and dealt < health.current and
        damage_cause ~= causes.POISON then
        sleep.awaken(ctx, player)
    end

    curl.on_damage(ctx, player, dealt, damage_cause)

    if cause ~= causes.POISON then
        reactions.before_hp(ctx, player, dealt)
    end

    if cause ~= causes.POISON and cause ~= causes.FLAY then
        dealt = spirit_shield.absorb(ctx, player, dealt, health.current)
    end

    if dealt > 0 and dealt < health.current and
        damage_cause ~= causes.POISON then
        sleep.awaken(ctx, player)
    end

    health.current = math.max(0, health.current - dealt)
    ctx:set(player, "core.health", health)

    if health.current > 0 then
        reactions.after_hp(ctx, player, dealt, damage_cause, attacker)
        sanguine.on_damage(ctx, player, dealt)
    else
        extra_lives.on_lethal(ctx, player)
    end

    if attacker and attacker ~= player and dealt > 0 then
        statuses.anguish_reflect(ctx, attacker, dealt)
    end

    return health, dealt
end

-- Example: health_policy.can_heal(ctx, player) with active Death's Door -> false healing permission
-- Check active heal-blocking effects before vampiric and other combat healing writes HP.
function health_policy.can_heal(ctx, player)
    return not statuses.death_door_active(ctx, player)
end

return health_policy
