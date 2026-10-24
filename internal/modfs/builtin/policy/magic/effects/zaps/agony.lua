local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local torment = require("policy.combat.torment")
local player_contact = require("policy.combat.player_contact")

local agony = {}

-- Example: A living visible rat behind a clear ray makes Agony targetable; a wall blocks it.
-- Scan living monsters through range, visibility, and projectile clearance before offering a cast.
function agony.can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local distance = math.max(math.abs(location.x - origin.x),
                math.abs(location.y - origin.y))

            if health.current > 0 and torment.susceptible(definition) and
                distance <= reach and location.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    location.x, location.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    location.x, location.y) then
                return true
            end
        end
    end

    return false
end

-- Trace the first beam contact, then apply willpower and torment resistance so Agony cannot kill outright.
function agony.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "Agony finds no target.")
        return
    end

    local target = contact.actor
    local definition, health = damage.monster(ctx, target)

    if not definition then
        error("Agony struck an actor without health")
    end

    player_contact.report(ctx, target, definition)

    if not torment.susceptible(definition) or health.current <= 0 then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    -- zap-data.h:ZAP_AGONY enchants at 5*power (cap 100).
    local enchant_power = 5 * math.min(power, 100)

    if will.resists(ctx, definition, enchant_power,
        target, nil, player) then
        ctx:emit("spell", "The " .. definition.name .. " resists Agony.")
        return
    end

    -- spl-goditem.cc:torment_cell cuts current HP by 50%-5% per rN,
    -- less one point, so Agony itself never kills the target.
    local amount = torment.monster_loss(ctx, target, definition,
        health.current)

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "The " .. definition.name .. " convulses!")
end

registry.add(spells.SPELL_AGONY, agony)

return agony
