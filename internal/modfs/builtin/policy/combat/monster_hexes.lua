local beam = require("policy.combat.monster_beams")
local hex = require("policy.combat.monster_spells.hex")
local component = require("constants.component")
local senses = require("policy.character.senses")

local hexes = {}

-- Targeted enchantments use the same physical trace as other source zaps.
-- Spell-specific viability is checked before tracing; contact resistance
-- and effects belong to the spell's named hook.
function hexes.plan(ctx, caster, foe, profile, rule)
    if rule and rule.viable and
        not rule.viable(ctx, caster, foe, profile) then
        return nil
    end

    return beam.plan(ctx, caster, foe, profile)
end

-- Reuse the beam path but suppress direct damage; each contact dispatches its hex rule.
function hexes.resolve(ctx, caster, foe, profile, plan, rule)
    local hook = {
        skip_damage = hexes.skip_damage,
        suppress_hit_message = true,
    }

    -- Piercing contacts need a fresh viability and will check for their own defender.
    function hook.after_hit(context, source, defender, source_profile)
        -- A piercing hex can hit several actors. Recheck each contact;
        -- planning only validated the originally selected foe.
        if rule.viable and not rule.viable(context, source, defender,
            source_profile) then
            return
        end

        local resisted = false

        if rule.resisted then
            resisted = rule.resisted(context, source, defender,
                source_profile)
        elseif rule.saving_throw ~= false then
            resisted = hex.resisted(context, source, defender,
                source_profile)
        end

        if resisted then
            if context:has(defender, component.PLAYER) or
                senses.player_sees_actor(context, defender) then
                context:emit("combat", "The enchantment is resisted.")
            end

            return
        end

        rule.apply(context, source, defender, source_profile)
    end

    return beam.resolve(ctx, caster, foe, profile, plan, hook)
end

-- Example: hexes.skip_damage() with hex-only contact -> true to skip beam HP damage
-- Tell the shared beam resolver that hex contacts change state without rolling direct HP damage.
function hexes.skip_damage()
    return true
end

return hexes
