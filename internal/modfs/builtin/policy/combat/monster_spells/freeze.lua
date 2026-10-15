local spells = require("policy.combat.spells")
local player_health_policy = require("policy.combat.player_health")
local magic_damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local monster_stats = require("policy.combat.monster_stats")

local freeze = {}

function freeze.can_cast(_, caster_pos, player_pos)
    return caster_pos.level_id == player_pos.level_id and
        math.abs(caster_pos.x - player_pos.x) <= 1 and
        math.abs(caster_pos.y - player_pos.y) <= 1 and
        (caster_pos.x ~= player_pos.x or caster_pos.y ~= player_pos.y)
end

function freeze.resolve(ctx, caster, _, definition, player_health)
    local player = ctx:player()
    local damage = magic_damage.player_elemental(ctx, player,
        spells.freeze(ctx,
            monster_stats.hit_dice(ctx, caster, definition)),
        resistances.COLD)
    player_health_policy.damage(ctx, player, damage, false, caster)
    ctx:emit("combat", "You are frozen.")
end

return freeze
