local duration = require("policy.combat.monster_support.duration")
local enchant = require("policy.combat.monster_support.invisibility")
local self_target = require("policy.combat.monster_support.self_target")
local display = require("policy.combat.monster_support.display")
local channels = require("constants.message_channels")
local senses = require("policy.character.senses")

local invisibility = {}

-- Invisibility uses the existing enchant record already read by perception.
function invisibility.plan(ctx, caster, foe)
    if enchant.active(ctx, caster) then
        return nil
    end

    if not self_target.useful(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Preserve blindness and corrosion while granting a new invisibility timer.
function invisibility.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    -- Remember pre-cast perception: granting invisibility immediately makes
    -- the monster unnameable, but an observed disappearance should be shown.
    local seen = senses.player_sees_actor(ctx, caster)

    enchant.grant(ctx, caster, duration.beneficial(ctx, caster))

    if seen then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " flickers and vanishes.")
    end
end

return invisibility
