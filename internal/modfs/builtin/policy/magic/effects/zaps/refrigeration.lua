local component = require("constants.component")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local cold_exposure = require("policy.magic.effects.statuses.monster_cold_exposure")
local area = require("policy.combat.monster_area.refrigeration")
local streams = require("constants.rng_streams")
local resistances = require("constants.resistance_ids")
local attack_conduct = require("policy.religion.conduct.attack")

local refrigeration = {}
local SIGHT_RADIUS = 7

-- Example: Ozocubu’s Refrigeration rolls cold damage for visible monsters within seven cells.
-- Snapshot all actors before damage, then process visible victims without order-dependent adjacency.
function refrigeration.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    -- spl-damage.cc:_cast_los_attack_spell uses actor_near_iterator with
    -- LOS_NO_TRANS; the spell catalog's -1 denotes an untargeted spell.
    local reach = SIGHT_RADIUS
    local sides = area.base_sides(ctx, power, streams.SPELL)
    local snapshot = area.snapshot(ctx, player)
    local targets = {}

    for _, entry in ipairs(snapshot) do
        local position = entry.position
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if entry.entity ~= player and distance <= reach and
            ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
                reach, position.x, position.y) then
            local actor = ctx:get(entry.entity, component.ACTOR)

            targets[#targets + 1] = {
                entity = entry.entity,
                definition = catalog.get(categories.MONSTERS,
                    actor.kind_id),
            }
        end
    end

    ctx:emit(channels.SPELL,
        "The heat is drained from your surroundings.")

    for _, hit in ipairs(targets) do
        local target = hit.entity
        local health = ctx:get(target, component.HEALTH)

        if health.current > 0 then
            local definition = hit.definition
            attack_conduct.report(ctx, target, definition)
            local nearby = area.adjacent(snapshot, target)
            local raw = area.raw_damage(ctx, sides,
                nearby, streams.SPELL)

            local ac = defense.armour(ctx, target, definition)
            local after_ac = math.max(0,
                raw - ctx:random(streams.SPELL, ac + 1))
            local amount = damage.elemental(after_ac, definition,
                resistances.COLD)

            local remaining = damage.apply(ctx, target, amount)
            ctx:emit(channels.SPELL,
                "The refrigeration chills the " ..
                definition.name .. ".")

            if remaining > 0 then
                cold_exposure.apply(ctx, target, definition, 5,
                    streams.SPELL)
            end
        end
    end
end

registry.add(spells.SPELL_OZOCUBUS_REFRIGERATION, refrigeration)

return refrigeration
