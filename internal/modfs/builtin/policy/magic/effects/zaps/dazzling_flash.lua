local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local monster_stats = require("policy.combat.monster_stats")

local dazzling_flash = {}

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function susceptible(definition)
    return not contains(definition.flags, "M_UNBLINDABLE") and
        not contains(definition.holiness, "MH_UNDEAD") and
        not contains(definition.holiness, "MH_NONLIVING") and
        not contains(definition.holiness, "MH_PLANT")
end

local function targets(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local found = {}

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and susceptible(definition) and
                position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) then
                found[#found + 1] = {
                    entity = target,
                    definition = definition,
                }
            end
        end
    end

    return found
end

function dazzling_flash.resolve(ctx, player, _, spell, power)
    local denominator = 150 - math.min(power, 50)

    for _, target in ipairs(targets(ctx, player, spell)) do
        local definition = target.definition
        local hd = monster_stats.hit_dice(ctx, target.entity, definition)
        local numerator = 95 - hd * 4

        if numerator > 0 and
            (numerator >= denominator or
                ctx:random("spell", denominator) < numerator) then
            local state = ctx:get(target.entity, component.MONSTER_ENCHANT) or {
                blind_aut = 0,
                corrosion_aut = 0,
            }

            state.blind_aut = state.blind_aut +
                (4 + ctx:random("spell", 5)) * 10

            if ctx:has(target.entity, component.MONSTER_ENCHANT) then
                ctx:set(target.entity, component.MONSTER_ENCHANT, state)
            else
                ctx:add(target.entity, component.MONSTER_ENCHANT, state)
            end

            ctx:emit("spell", "The " .. definition.name .. " is dazzled.")
        end
    end
end

function dazzling_flash.can_target(ctx, player, spell)
    return #targets(ctx, player, spell) > 0
end

registry.add(spells.SPELL_DAZZLING_FLASH, dazzling_flash)

return dazzling_flash
