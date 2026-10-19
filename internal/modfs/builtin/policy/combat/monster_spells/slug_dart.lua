local fighter = require("policy.combat.fighter")
local spells = require("policy.combat.spells")
local direct = require("policy.combat.monster_direct")
local display = require("policy.combat.monster_support.display")
local monster_defense = require("policy.combat.monster_defense")
local monster_stats = require("policy.combat.monster_stats")
local reflection = require("policy.combat.reflection")
local catalog = require("policy.catalog")
local component = require("constants.component")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")
local senses = require("policy.character.senses")

local slug_dart = {}
slug_dart.reflectable = true

-- Slug Dart needs a clear projectile path before it can store an entity target.
-- Example: slug_dart.plan(ctx, caster, foe) with blocked path -> nil plan
-- Requires clear projectile travel to an entity.
function slug_dart.plan(ctx, caster, foe)
    local caster_pos = ctx:get(caster, component.POSITION)
    local foe_pos = ctx:get(foe, component.POSITION)

    if not caster_pos or not foe_pos then
        return nil
    end

    local clear = caster_pos.level_id == foe_pos.level_id and
        ctx:projectile_clear(caster_pos.level_id,
            caster_pos.x, caster_pos.y, foe_pos.x, foe_pos.y)

    if not clear then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Use the actual foe's armor, evasion, and shield. The player fighter
-- snapshot cannot defend an allied monster's target.
local function defense_for(ctx, foe)
    if ctx:has(foe, component.PLAYER) then
        return fighter.defense(ctx)
    end

    local actor = ctx:get(foe, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local combat = ctx:get(foe, component.COMBAT)

    if not combat then
        error("Slug Dart target has no combat state")
    end

    return {
        ev = monster_defense.evasion(ctx, foe, definition),
        ac = monster_defense.armour(ctx, foe, definition),
        shield_class = 0,
        shield_blocks = combat.shield_blocks,
        monster_shield = monster_defense.shield(ctx, foe, definition),
    }
end

-- Report the impact in the defender's voice without changing the result.
local function impact_message(ctx, foe, outcome)
    if ctx:has(foe, component.PLAYER) then
        if outcome.kind == "block" then
            return "You block the slug dart."
        end

        if outcome.kind == "hit" then
            return "The slug dart hits you for " .. outcome.damage ..
                " damage."
        end

        return "The slug dart misses you."
    end

    local name = display.name(ctx, foe)

    if outcome.kind == "block" then
        return "The " .. name .. " blocks the slug dart."
    end

    if outcome.kind == "hit" then
        return "The slug dart hits the " .. name .. " for " ..
            outcome.damage .. " damage."
    end

    return "The slug dart misses the " .. name .. "."
end

-- A reflecting monster's shield sends one new projectile contest back at
-- the caster. Its own attack attribution and shield count stay on actors,
-- with no player kill credit unless the player actually reflected the shot.
local function return_from_monster(ctx, caster, reflector, definition)
    local defense = defense_for(ctx, caster)
    local outcome = spells.slug_dart(ctx,
        monster_stats.spell_hit_dice(ctx, caster, definition), defense)
    local combat = ctx:get(caster, component.COMBAT)

    if not combat then
        error("reflected Slug Dart caster has no combat state")
    end

    combat.shield_blocks = outcome.shield_blocks
    ctx:set(caster, component.COMBAT, combat)
    direct.damage(ctx, reflector, caster, outcome.damage)

    if senses.player_sees_actor(ctx, reflector) then
        ctx:emit("combat", "The " .. display.name(ctx, reflector) ..
            " reflects the slug dart!")
    end

    -- The returning dart may travel toward an unseen or invisible caster.
    -- Describe that impact only when its victim is also perceivable.
    if senses.player_sees_actor(ctx, caster) then
        ctx:emit("combat", impact_message(ctx, caster, outcome))
    end
end

-- Resolve the saved entity and its own shield-block count before HP loss.
function slug_dart.resolve(ctx, caster, foe, _, plan)
    local victim = target.require_entity(plan, foe)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local defense = defense_for(ctx, victim)
    local outcome = spells.slug_dart(ctx,
        monster_stats.spell_hit_dice(ctx, caster, definition), defense)
    local combat = ctx:get(victim, component.COMBAT)

    if not combat then
        error("Slug Dart target has no combat state")
    end

    -- Persist the shield-block count before applying HP loss; later attacks use this combat state.
    combat.shield_blocks = outcome.shield_blocks
    ctx:set(victim, component.COMBAT, combat)
    direct.damage(ctx, caster, victim, outcome.damage)
    if ctx:has(victim, component.PLAYER) or
        senses.player_sees_actor(ctx, victim) then
        ctx:emit("combat", impact_message(ctx, victim, outcome))
    end

    -- Only a blocked dart can rebound. A player amulet and a monster's
    -- reflecting shield keep their own health and kill-credit paths.
    if outcome.kind ~= "block" or not slug_dart.reflectable then
        return
    end

    if ctx:has(victim, component.PLAYER) and
        reflection.active(ctx, victim) then
        local returned = reflection.return_defense(ctx, caster,
            definition)

        if returned then
            reflection.begin(ctx, "slug dart")

            local rebound = spells.slug_dart(ctx,
                monster_stats.spell_hit_dice(ctx, caster, definition), returned)

            reflection.return_outcome(ctx, victim, caster, definition,
                "slug dart", rebound)
        end
    elseif defense.monster_shield and
        defense.monster_shield.reflects then
        return_from_monster(ctx, caster, victim, definition)
    end
end

return slug_dart
