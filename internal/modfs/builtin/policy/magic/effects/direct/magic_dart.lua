local catalog = require("policy.catalog")
local monster_defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local spell_range = require("policy.magic.range")
local trajectory = require("policy.combat.trajectory")
local target = require("policy.magic.effects.direct.target")
local spells = require("ids.spells")
local player_contact = require("policy.combat.player_contact")
local effect = {}

-- Source: spl-zap.cc:SPELL_MAGIC_DART -> ZAP_MAGIC_DART and
-- zap-data.h:dicedef_calculator<1, 3, 1, 5> with automatic hit.
local function resolve(ctx, player, intent, spell, spell_power)
    local position = ctx:get(player, "core.position")
    local reach = spell_range.for_spell(ctx, player, spell)
    local impact = trajectory.trace(ctx, position.level_id,
        position.x, position.y,
        position.x + intent.dx, position.y + intent.dy, reach)
    local contact = impact.contacts[1]

    if not contact then
        ctx:emit("spell", "The magic dart dissipates.")

        return
    end

    local target = contact.actor
    local actor = ctx:get(target, "core.actor")
    local health = ctx:get(target, "core.health")

    if not actor or not health then
        error("magic dart struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    player_contact.report(ctx, target, definition)
    local sides = 3 + math.floor(spell_power / 5)
    local rolled = 1 + ctx:random("spell", sides)
    local ac = monster_defense.armour(ctx, target, definition)
    local dealt = math.max(0, rolled - ctx:random("spell", ac + 1))

    damage.apply(ctx, target, dealt)

    ctx:emit("spell", "The magic dart hits the " .. definition.name .. ".")
end

-- Example: A hostile in current dart range behind a wall does not pass the clear-ray target check.
-- Use the spell's current power-scaled range and a clear ray for a direct dart.
function effect.can_target(ctx, player, spell)
    return target.visible_hostile(ctx, player,
        spell_range.for_spell(ctx, player, spell), true)
end

effect.resolve = resolve

registry.add(spells.SPELL_MAGIC_DART, effect)

return effect
