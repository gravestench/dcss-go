local fighter = require("policy.combat.fighter")
local spells = require("policy.combat.spells")
local player_health_policy = require("policy.combat.player_health")
local monster_stats = require("policy.combat.monster_stats")

local slug_dart = {}

function slug_dart.can_cast(ctx, caster_pos, player_pos)
    return caster_pos.level_id == player_pos.level_id and
        ctx:projectile_clear(caster_pos.level_id,
            caster_pos.x, caster_pos.y, player_pos.x, player_pos.y)
end

function slug_dart.resolve(ctx, caster, _, definition, player_health)
    local player = ctx:player()
    local defense = fighter.defense(ctx)
    local outcome = spells.slug_dart(ctx,
        monster_stats.hit_dice(ctx, caster, definition), defense)
    local combat = ctx:get(player, "core.combat")

    if not combat then
        error("player has no combat state")
    end

    combat.shield_blocks = outcome.shield_blocks
    ctx:set(player, "core.combat", combat)
    player_health_policy.damage(ctx, player, outcome.damage, false, caster)

    local message = "The slug dart misses you."

    if outcome.kind == "block" then
        message = "You block the slug dart."
    elseif outcome.kind == "hit" then
        message = "The slug dart hits you for " .. outcome.damage .. " damage."
    end

    ctx:emit("combat", message)
end

return slug_dart
