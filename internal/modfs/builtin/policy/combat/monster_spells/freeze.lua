local spells = require("policy.combat.spells")
local player_health_policy = require("policy.combat.player_health")
local magic_damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local monster_stats = require("policy.combat.monster_stats")
local catalog = require("policy.catalog")
local component = require("constants.component")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")

local freeze = {}

-- Freeze is adjacent-only and cannot target the caster's own cell.
-- Example: freeze.plan(ctx, caster, foe) with nonadjacent foe -> nil plan
-- Rejects targets outside adjacent range.
function freeze.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local player_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not player_pos then
        return nil
    end

    local adjacent = caster_pos.level_id == player_pos.level_id and
        math.abs(caster_pos.x - player_pos.x) <= 1 and
        math.abs(caster_pos.y - player_pos.y) <= 1 and
        (caster_pos.x ~= player_pos.x or caster_pos.y ~= player_pos.y)

    if not adjacent then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Caster hit dice feed the cold roll before player cold resistance and HP damage.
function freeze.resolve(ctx, caster, foe, _, plan)
    local player = target.require_entity(plan, foe)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local damage = magic_damage.player_elemental(ctx, player,
        spells.freeze(ctx,
            monster_stats.hit_dice(ctx, caster, definition)),
        resistances.COLD)
    player_health_policy.damage(ctx, player, damage, false, caster)
    ctx:emit("combat", "You are frozen.")
end

return freeze
