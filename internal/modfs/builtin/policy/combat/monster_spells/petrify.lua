local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local petrification = require("policy.combat.player_petrification")
local resistance = require("policy.combat.player_resistance")
local monster_stasis = require("policy.magic.effects.statuses.monster_stasis")
local display = require("policy.combat.monster_support.display")
local catalog = require("policy.catalog")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")
local spells = require("ids.spells")
local senses = require("policy.character.senses")

local petrify = {}

-- Petrifying gaze requires a clear line within seven cells before it can form an entity plan.
-- Example: petrify.plan(ctx, caster, foe) with foe beyond clear sight -> nil plan
-- Requires clear sight within seven cells.
function petrify.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not foe_pos then
        return nil
    end

    if caster_pos.level_id ~= foe_pos.level_id then
        return nil
    end

    local distance = math.max(math.abs(caster_pos.x - foe_pos.x),
        math.abs(caster_pos.y - foe_pos.y))

    local clear = distance <= 7 and ctx:projectile_clear(caster_pos.level_id,
        caster_pos.x, caster_pos.y, foe_pos.x, foe_pos.y)

    if not clear then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Check the foe's own innate resistance before the will contest, then store
-- the resulting stone phase in its player or monster status owner.
function petrify.resolve(ctx, caster, foe, _, plan)
    local victim = target.require_entity(plan, foe)
    local player = ctx:has(victim, component.PLAYER)
    local seen = player or senses.player_sees_actor(ctx, victim)

    if player and resistance.petrification(ctx, victim) then
        ctx:emit("spell", "You are unaffected by the petrifying gaze.")

        return
    end

    if not player and not monster_stasis.petrifiable(ctx, victim) then
        if seen then
            ctx:emit("spell", "The " .. display.name(ctx, victim) ..
                " is unaffected by the petrifying gaze.")
        end

        return
    end

    local profile = catalog.get("monster_beams", spells.SPELL_PETRIFY)

    if hex.resisted(ctx, caster, victim, profile) then
        if player then
            ctx:emit("spell", "You resist the petrifying gaze.")
        elseif seen then
            ctx:emit("spell", "The " .. display.name(ctx, victim) ..
                " resists the petrifying gaze.")
        end

        return
    end

    if player then
        petrification.apply(ctx, victim)

        return
    end

    local phase = monster_stasis.apply_petrify(ctx, victim)

    if seen and phase == "petrifying" then
        ctx:emit("spell", "The " .. display.name(ctx, victim) ..
            " is moving more slowly.")
    elseif seen and phase == "petrified" then
        ctx:emit("spell", "The " .. display.name(ctx, victim) ..
            " stops moving altogether!")
    end
end

return petrify
