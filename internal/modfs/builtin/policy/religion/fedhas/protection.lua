-- Theory of operation: Fedhas's shoot-through passive is a live relation
-- among the worshipper, the effect's source actor, and a plant target.
-- Projectile, beam, blast, and cloud owners ask this policy before they
-- roll contact or apply an effect. No persistent immunity flag is needed.
local attitudes = require("constants.attitude")
local attribution = require("constants.cloud_attribution")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local fedhas = require("policy.religion.gods.fedhas")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")

local protection = {}

-- Every effect reads the same permanent monster class instead of a
-- remembered summon source or an English name.
local function protected_plant(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    return definition and fedhas.plant_class(definition) or false
end

-- Source god_protects requires a player-side agent and an aligned or
-- neutral plant. Read current allegiance and penance for every contact;
-- desertion, charm, and monster conversion may change them mid-level.
function protection.ignores(ctx, attacker, target)
    if not attacker or not target or attacker == target then
        return false
    end

    local player = ctx:player()

    if not fedhas.passive_active(ctx, player) or
        (attacker ~= player and
            targets.attitude(ctx, attacker) ~= attitudes.FRIENDLY) then
        return false
    end

    if not protected_plant(ctx, target) then
        return false
    end

    local attitude = targets.attitude(ctx, target)

    return attitude == attitudes.NEUTRAL or
        targets.aligned(ctx, attacker, target)
end

-- Cloud exposure uses saved kill attribution, not a living source actor.
-- Source clouds can persist after their creator dies; player-side clouds
-- still spare friendly and neutral protected plants under the passive.
function protection.ignores_cloud(ctx, target, kill_category)
    if kill_category ~= attribution.PLAYER and
        kill_category ~= attribution.FRIENDLY then
        return false
    end

    if not fedhas.passive_active(ctx, ctx:player()) or
        not protected_plant(ctx, target) then
        return false
    end

    local attitude = targets.attitude(ctx, target)

    return attitude == attitudes.FRIENDLY or
        attitude == attitudes.GOOD_NEUTRAL or
        attitude == attitudes.NEUTRAL
end

-- Source prints a protection notice only when the player can see the
-- plant. Call this after ignores() returns true; tracers use the pure
-- predicate without producing a gameplay event.
function protection.report(ctx, attacker, target)
    if not senses.player_sees_actor(ctx, target) then
        return
    end

    local possessive = attacker == ctx:player() and "your" or "a"

    ctx:emit(channels.RELIGION,
        "Fedhas protects " .. possessive .. " plant from harm.")
end

-- Area rays detonate at their first vulnerable actor. Report each
-- sheltered plant they pass so the player's view agrees with the actual
-- endpoint; the planner can still use ignores() without side effects.
function protection.first_unprotected_contact(ctx, attacker, contacts)
    for _, contact in ipairs(contacts) do
        if protection.ignores(ctx, attacker, contact.actor) then
            protection.report(ctx, attacker, contact.actor)
        else
            return contact
        end
    end

    return nil
end

return protection
