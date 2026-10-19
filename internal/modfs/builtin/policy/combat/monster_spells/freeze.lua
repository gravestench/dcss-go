local spells = require("policy.combat.spells")
local direct = require("policy.combat.monster_direct")
local display = require("policy.combat.monster_support.display")
local magic_damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local monster_stats = require("policy.combat.monster_stats")
local catalog = require("policy.catalog")
local component = require("constants.component")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")
local exposure = require("policy.magic.effects.statuses.monster_cold_exposure")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")

local freeze = {}

-- Freeze is adjacent-only and cannot target the caster's own cell.
-- Example: freeze.plan(ctx, caster, foe) with nonadjacent foe -> nil plan
-- Rejects targets outside adjacent range.
function freeze.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not foe_pos then
        return nil
    end

    local adjacent = caster_pos.level_id == foe_pos.level_id and
        math.abs(caster_pos.x - foe_pos.x) <= 1 and
        math.abs(caster_pos.y - foe_pos.y) <= 1 and
        (caster_pos.x ~= foe_pos.x or caster_pos.y ~= foe_pos.y)

    if not adjacent then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Caster HD determines the cold roll. The foe's actor kind then determines
-- its resistance and HP owner, so a friendly Endoplasm can freeze a monster.
function freeze.resolve(ctx, caster, foe, _, plan)
    local victim = target.require_entity(plan, foe)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local raw = spells.freeze(ctx,
        monster_stats.spell_hit_dice(ctx, caster, definition))
    local damage

    if ctx:has(victim, component.PLAYER) then
        damage = magic_damage.player_elemental(ctx, victim, raw,
            resistances.COLD)
    else
        damage = magic_damage.monster_elemental(ctx, victim, raw,
            resistances.COLD)
    end

    -- Source reports the visible freeze before HP loss and any resulting
    -- cold-blooded slow; offscreen casts still apply both actor effects.
    if not ctx:has(victim, component.PLAYER) and
        senses.player_sees_actor(ctx, victim) then
        ctx:emit("combat", "The " .. display.name(ctx, victim) ..
            " is frozen.")
    end

    direct.damage(ctx, caster, victim, damage)

    if ctx:has(victim, component.PLAYER) then
        ctx:emit("combat", "You are frozen.")
    else
        local health = ctx:get(victim, component.HEALTH)

        if health and health.current > 0 then
            local victim_actor = ctx:get(victim, component.ACTOR)
            local victim_definition = catalog.get("monsters",
                victim_actor.kind_id)

            exposure.apply(ctx, victim, victim_definition, damage,
                streams.MONSTER_SPELL)
        end

    end
end

return freeze
