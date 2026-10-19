local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local petrification = require("policy.combat.player_petrification")
local resistance = require("policy.combat.player_resistance")
local catalog = require("policy.catalog")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")
local spells = require("ids.spells")

local petrify = {}

-- Petrifying gaze requires a clear line within seven cells before it can form an entity plan.
-- Example: petrify.plan(ctx, caster, foe) with foe beyond clear sight -> nil plan
-- Requires clear sight within seven cells.
function petrify.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local player_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not player_pos then
        return nil
    end

    if caster_pos.level_id ~= player_pos.level_id then
        return nil
    end

    local distance = math.max(math.abs(caster_pos.x - player_pos.x),
        math.abs(caster_pos.y - player_pos.y))

    local clear = distance <= 7 and ctx:projectile_clear(caster_pos.level_id,
        caster_pos.x, caster_pos.y, player_pos.x, player_pos.y)

    if not clear then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Innate petrification resistance precedes the ordinary hex resistance roll.
function petrify.resolve(ctx, caster, foe, _, plan)
    local player = target.require_entity(plan, foe)
    if resistance.petrification(ctx, player) then
        ctx:emit("spell", "You are unaffected by the petrifying gaze.")

        return
    end

    local profile = catalog.get("monster_beams", spells.SPELL_PETRIFY)

    if hex.resisted(ctx, caster, player, profile) then
        ctx:emit("spell", "You resist the petrifying gaze.")

        return
    end

    petrification.apply(ctx, player)
end

return petrify
