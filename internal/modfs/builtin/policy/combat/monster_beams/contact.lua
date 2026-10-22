local catalog = require("policy.catalog")
local calculators = require("policy.combat.monster_beams.calculators")
local component = require("constants.component")
local causes = require("constants.damage_causes")
local damage = require("policy.combat.monster_beams.damage")
local defense = require("policy.combat.monster_beams.defense")
local fighter = require("policy.combat.fighter")
local monster_defense = require("policy.combat.monster_defense")
local repulsion = require("policy.combat.monster_support.repulsion")
local monster_health = require("policy.combat.monster_health")
local player_health = require("policy.combat.player_health")
local reflection = require("policy.combat.reflection")
local senses = require("policy.character.senses")

local contact = {}

-- Snapshot the defender before hit, block, and resistance rolls can mutate combat state.
local function defender_snapshot(ctx, defender)
    if ctx:has(defender, component.PLAYER) then
        local snapshot = fighter.defense(ctx)

        snapshot.reflects = reflection.active(ctx, defender)

        return snapshot
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        error("monster beam defender has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local shield = monster_defense.shield(ctx, defender, definition)

    return {
        ev = monster_defense.evasion(ctx, defender, definition),
        missile_repulsion = repulsion.active(ctx, defender),
        ac = monster_defense.armour(ctx, defender, definition),
        monster_shield = shield,
        reflects = shield and shield.reflects or false,
    }
end

-- After contact succeeds, apply the captured armour before flavor resistance;
-- return pre- and post-armour values for hit hooks and reporting.
local function calculate_hit(ctx, defender, profile, power, snapshot)
    local dice = calculators.damage_dice(ctx, profile, power)
    local raw = calculators.roll_damage(ctx, dice,
        profile.rng_stream)
    local after_armour = damage.armour(ctx, raw, snapshot.ac, profile)
    local dealt = damage.resisted(ctx, defender, after_armour, profile)

    return dealt, dice, after_armour
end

-- Dispatch to player or monster health so death credit and reactions stay in their own domains.
local function deliver_hit(ctx, caster, defender, amount)
    if ctx:has(defender, component.PLAYER) then
        player_health.damage(ctx, defender, amount, false,
            caster, causes.BEAM)
    else
        monster_health.damage(ctx, defender, amount, caster)
    end
end

-- Example: contact.register_block(ctx, defender) with monster blocks once -> shield block count increases
-- Shield blocks accumulate in the defender component for later bypass calculations.
function contact.register_block(ctx, defender)
    if not ctx:has(defender, component.PLAYER) then
        monster_defense.register_block(ctx, defender)

        return
    end

    local combat = ctx:get(defender, component.COMBAT)

    if not combat then
        error("beam defender has no combat state")
    end

    combat.shield_blocks = combat.shield_blocks + 1
    ctx:set(defender, component.COMBAT, combat)
end

-- Contact resolves shield, evasion, damage, and flavor hooks for one actor;
-- the caller decides whether the ray continues or reflects.
function contact.resolve(ctx, caster, defender, profile,
    power, to_hit, hook, incoming)
    local snapshot = defender_snapshot(ctx, defender)
    local outcome = defense.roll(ctx, snapshot, to_hit, profile)

    outcome.target = defender
    outcome.source = caster

    if outcome.kind == "hit" then
        if hook and hook.skip_damage and
            hook.skip_damage(ctx, defender) then
            outcome.damage = 0
            outcome.after_armour = 0
            outcome.dice = {
                count = 0,
                sides = 0,
            }
        else
            outcome.damage, outcome.dice, outcome.after_armour =
                calculate_hit(ctx, defender, profile, power, snapshot)
        end

        if hook and hook.before_damage then
            hook.before_damage(ctx, caster, defender, profile, outcome)
        end

        if outcome.damage > 0 then
            deliver_hit(ctx, caster, defender, outcome.damage)
        end

        if hook and hook.after_hit then
            hook.after_hit(ctx, caster, defender, profile, outcome,
                incoming)
        end

        if (not hook or not hook.suppress_hit_message) and
            (ctx:has(defender, component.PLAYER) or
                senses.player_sees_actor(ctx, defender)) then
            ctx:emit("combat", "The " .. profile.name .. " hits.")
        end
    end

    return outcome
end

return contact
