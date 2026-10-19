-- Source: spl-other.cc:_intoxicate_monsters and cast_intoxicate.
local component = require("constants.component")
local catalog = require("policy.catalog")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local statuses = require("policy.magic.effects.statuses.player")

local intoxication = {}

-- Read the catalog's explicit poison level for intoxication's immunity and partial-resist rolls.
local function poison_resistance(definition)
    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == "MR_RES_POISON" then
            return resistance.level
        end
    end

    return 0
end

-- Only sapient monsters below full poison immunity can be confused by this spell.
local function susceptible(definition)
    local intelligence = definition.intelligence_id

    if intelligence ~= "I_HUMAN" and intelligence ~= "I_NORMAL" and
        intelligence ~= "I_HIGH" then
        return false
    end

    return poison_resistance(definition) < 3
end

-- Snapshot visible susceptible monsters so cast eligibility and resolution see the same target class.
local function visible_targets(ctx, player)
    local targets = {}
    local origin = ctx:get(player, component.POSITION)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)

            if health.current > 0 and position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    position.x, position.y) then
                local actor = ctx:get(target, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                if susceptible(definition) then
                    targets[#targets + 1] = {
                        entity = target,
                        definition = definition,
                    }
                end
            end
        end
    end

    return targets
end

-- Example: One visible susceptible monster makes Intoxication targetable before its resistance roll.
-- Use the cast path's susceptible-target scan to avoid offering a cast with no possible victims.
function intoxication.can_target(ctx, player)
    return #visible_targets(ctx, player) > 0
end

-- Intoxication rolls against visible susceptible monsters after the player pays the casting cost.
function intoxication.cast(ctx, player, power)
    ctx:emit("spell", "You attempt to intoxicate your foes!")
    local count = 0

    for _, target in ipairs(visible_targets(ctx, player)) do
        local resistance = poison_resistance(target.definition)
        local resisted = resistance >= 1 and ctx:random("spell", 3) < 2
        local chance = 40 + math.floor(power / 3)

        if not resisted and ctx:random("spell", 100) < chance then
            confusion.apply_innate(ctx, target.entity, target.definition)
            ctx:emit("spell", "The " .. target.definition.name ..
                " looks rather confused.")
            count = count + 1
        end
    end

    if count > 0 then
        ctx:emit("warning", "The world spins around you!")
        statuses.add_vertigo(ctx, player,
            4 + count + ctx:random("spell", count + 1))
    end
end

return intoxication
