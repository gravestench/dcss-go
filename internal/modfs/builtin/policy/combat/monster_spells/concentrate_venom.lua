local ally_target = require("policy.combat.monster_support.ally_target")
local display = require("policy.combat.monster_support.display")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local venom = require("policy.combat.monster_tactical.concentrate_venom")

local effect = {}

-- The source buff beam chooses the nearest genuinely allied poison user
-- whose first-contact ray is clear, then commits that actor in the intent.
function effect.plan(ctx, caster)
    return ally_target.plan(ctx, caster,
        spells.SPELL_CONCENTRATE_VENOM, venom.benefits)
end

-- A later actor or wall may intercept the original ray; the cast then
-- spends its action without retargeting another ally.
function effect.resolve(ctx, caster, _, _, plan)
    local recipient = ally_target.selected(ctx, caster, plan)

    if not recipient or not venom.benefits(ctx, recipient) or
        not venom.grant(ctx, recipient) then
        return
    end

    if senses.player_sees_actor(ctx, recipient) then
        ctx:emit("spell", "The " .. display.name(ctx, recipient) ..
            " seems to grow toxic.")
    end
end

return effect
