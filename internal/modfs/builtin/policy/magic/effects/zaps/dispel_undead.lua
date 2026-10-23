local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local attack_conduct = require("policy.religion.conduct.attack")

local dispel_undead = {}

-- Look up undead holiness in the catalog list before the beam can damage a target.
local function undead(definition)
    for _, holiness in ipairs(definition.holiness or {}) do
        if holiness == "MH_UNDEAD" then
            return true
        end
    end

    return false
end

-- Example: A visible undead target on a clear ray can receive Dispel Undead damage.
-- Require undead holiness and an unobstructed visible path before presenting the spell as targetable.
function dispel_undead.can_target(ctx, player, spell)
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

            if health.current > 0 and undead(definition) and
                location.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    location.x, location.y) and
                ctx:projectile_clear(location.level_id, origin.x, origin.y,
                    location.x, location.y) then
                return true
            end
        end
    end

    return false
end

-- Trace first contact and gate damage on undead holiness, leaving living monsters unaffected.
function dispel_undead.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "Dispel Undead finds no target.")
        return
    end

    local target = contact.actor
    local definition = damage.monster(ctx, target)

    if not definition then
        error("Dispel Undead struck an actor without health")
    end

    attack_conduct.report(ctx, target, definition)

    if not undead(definition) then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    -- zap-data.h:ZAP_DISPEL_UNDEAD uses calcdice<3,20,3,4> and no AC.
    -- beam.cc:has_saving_throw excludes this flavour.
    local capped = math.min(power, 100)
    local maximum = 20 + math.floor(3 * capped / 4)
    local sides = math.floor(maximum / 3)
    local remainder = maximum % 3

    if remainder > 0 and ctx:random("spell", 3) < remainder then
        sides = sides + 1
    end

    local amount = 0

    for _ = 1, 3 do
        amount = amount + 1 + ctx:random("spell", sides)
    end

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "The " .. definition.name .. " is dispelled.")
end

registry.add(spells.SPELL_DISPEL_UNDEAD, dispel_undead)

return dispel_undead
