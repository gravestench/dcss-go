-- Malign Offering converts one beam victim's actual HP loss into healing
-- for the caster's living allies near that victim. Source: beam.cc.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local life = require("policy.combat.life_transfer")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_MALIGN_OFFERING)
local SIGHT_RADIUS = 7

effect.suppress_hit_message = true

-- Use the beam prospect so walls and intervening actors determine whether
-- this offering can reach the selected enemy before its action is spent.
function effect.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- Save the victim's HP and cell before generic beam contact applies damage.
-- The heal must use dealt HP and the victim's original cell even if it dies.
function effect.before_damage(ctx, _, victim, _, outcome)
    local health = ctx:get(victim, component.HEALTH)
    local position = ctx:get(victim, component.POSITION)

    outcome.offering_before = health and health.current or 0
    outcome.offering_position = position
    outcome.offering_visible = ctx:has(victim, component.PLAYER) or
        senses.player_sees_actor(ctx, victim)
end

-- Source heals each aligned, living actor other than the sacrifice by two
-- thirds of real HP damage. A hidden or dead victim still provides the same
-- field; only player-facing messages depend on current perception.
function effect.after_hit(ctx, caster, victim, _, outcome)
    local health = ctx:get(victim, component.HEALTH)
    local dealt = math.max(0,
        outcome.offering_before - (health and health.current or 0))

    if dealt <= 0 then
        return
    end

    if outcome.offering_visible then
        local victim_name = ctx:has(victim, component.PLAYER) and
            "Your" or ("The " .. display.name(ctx, victim) .. "'s")

        ctx:emit(channels.SPELL,
            victim_name .. " life force is offered up.")
    end

    local center = outcome.offering_position
    local amount = math.max(1, math.floor(dealt * 2 / 3))

    for _, ally in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if ally ~= victim and targets.aligned(ctx, caster, ally) and
            life.offering_recipient(ctx, ally) then
            local position = ctx:get(ally, component.POSITION)
            local distance = math.max(math.abs(position.x - center.x),
                math.abs(position.y - center.y))

            if position.level_id == center.level_id and
                distance <= SIGHT_RADIUS and
                ctx:visible_no_trans(center.level_id, center.x,
                    center.y, SIGHT_RADIUS, position.x, position.y) then
                local gained = life.heal(ctx, ally, amount)

                if gained > 0 and
                    (ctx:has(ally, component.PLAYER) or
                        senses.player_sees_actor(ctx, ally)) then
                    if ctx:has(ally, component.PLAYER) then
                        ctx:emit(channels.SPELL,
                            "You feel life coursing into your body.")
                    else
                        ctx:emit(channels.SPELL, "The " ..
                            display.name(ctx, ally) .. " is healed.")
                    end
                end
            end
        end
    end
end

-- Beam contact owns shields, reflection, and impact; the hook only adds
-- life transfer after the selected actor has actually lost HP.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, effect)
end

return effect
