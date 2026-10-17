local fighter = require("policy.combat.fighter")
local spells = require("policy.combat.spells")
local player_health_policy = require("policy.combat.player_health")
local monster_stats = require("policy.combat.monster_stats")
local reflection = require("policy.combat.reflection")
local catalog = require("policy.catalog")
local component = require("constants.component")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")

local slug_dart = {}
slug_dart.reflectable = true

function slug_dart.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local player_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not player_pos then
        return nil
    end

    local clear = caster_pos.level_id == player_pos.level_id and
        ctx:projectile_clear(caster_pos.level_id,
            caster_pos.x, caster_pos.y, player_pos.x, player_pos.y)

    if not clear then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

function slug_dart.resolve(ctx, caster, foe, _, plan)
    local player = target.require_entity(plan, foe)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
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

    if outcome.kind == "block" and slug_dart.reflectable and
        reflection.active(ctx, player) then
        local returned = reflection.return_defense(ctx, caster,
            definition)

        if returned then
            reflection.begin(ctx, "slug dart")

            local rebound = spells.slug_dart(ctx,
                monster_stats.hit_dice(ctx, caster, definition), returned)

            reflection.return_outcome(ctx, player, caster, definition,
                "slug dart", rebound)
        end
    end
end

return slug_dart
