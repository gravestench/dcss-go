-- A direct strike names an actor without tracing a projectile. Keep target
-- validity and HP ownership here so individual spells only express their
-- source damage rule.
local catalog = require("policy.catalog")
local component = require("constants.component")
local causes = require("constants.damage_causes")
local fighter = require("policy.combat.fighter")
local monster_defense = require("policy.combat.monster_defense")
local monster_health = require("policy.combat.monster_health")
local player_health = require("policy.combat.player_health")
local range = require("policy.magic.range")
local roll = require("policy.combat.roll")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local direct = {}

-- Example: direct.plan(ctx, caster, foe, spell_id) returns an entity plan
-- through another actor but refuses a wall-hidden or out-of-range foe.
function direct.plan(ctx, caster, foe, spell_id)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local spell = catalog.get("spells", spell_id)
    local reach = range.for_power(spell, 0)
    local distance = math.max(math.abs(destination.x - source.x),
        math.abs(destination.y - source.y))

    if distance > reach or not ctx:visible(source.level_id,
        source.x, source.y, reach, destination.x, destination.y) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Recheck the saved handle and current level before dealing damage. An
-- intervening actor remains irrelevant, but a moved target is not replaced.
function direct.require(ctx, caster, foe, plan)
    target.require_entity(plan, foe)

    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        error("direct strike target left the caster's level")
    end

    return destination
end

-- Roll the target's current AC after a spell-specific resistance rule.
-- Example: direct.armour(ctx, monster, 10) uses the same live equipment
-- bonus as ordinary combat, then draws from the monster-spell stream.
function direct.armour(ctx, foe, raw)
    local ac

    if ctx:has(foe, component.PLAYER) then
        ac = fighter.defense(ctx).ac
    else
        local actor = ctx:get(foe, component.ACTOR)

        if not actor then
            error("direct strike target is not an actor")
        end

        local definition = catalog.get("monsters", actor.kind_id)
        ac = monster_defense.armour(ctx, foe, definition)
    end

    return math.max(0, raw - roll.spell(ctx, ac + 1))
end

-- Send attributed HP loss through the appropriate owner so waking,
-- retaliation, death protection, and kill credit remain consistent.
-- Example: direct.damage(ctx, caster, foe, 7) lets Smiting bypass AC.
function direct.damage(ctx, caster, foe, amount)
    if ctx:has(foe, component.PLAYER) then
        player_health.damage(ctx, foe, amount, false,
            caster, causes.BLAST)
    else
        monster_health.damage(ctx, foe, amount, caster)
    end
end

return direct
