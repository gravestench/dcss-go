-- Refrigeration's damage weakens when other nonconjured actors crowd a
-- victim. Snapshot those bodies before the first hit so kills earlier in
-- stable ECS iteration cannot make a later victim take more damage.
-- Source: spl-damage.cc:_count_adj_actors and _ozo_adj_dam.
-- Example: one adjacent body reduces a four-die side count to about 2/3.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local roll = require("policy.combat.roll")

local refrigeration = {}
local DICE_COUNT = 4
local BASE_MAXIMUM = 30
local POWER_NUMERATOR = 4
local POWER_DENOMINATOR = 9
local POWER_CAP = 200

-- Record all living bodies on the caster's level, including the caster.
-- Conjured actors do not dilute adjacent refrigeration damage.
function refrigeration.snapshot(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local bodies = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if health.current > 0 and
            position.level_id == origin.level_id then
            local conjured = false

            if entity ~= ctx:player() then
                local state = ctx:get(entity, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    state.kind_id)

                for _, flag in ipairs(definition.flags or {}) do
                    conjured = conjured or flag == flags.CONJURED
                end
            end

            bodies[#bodies + 1] = {
                entity = entity,
                position = position,
                conjured = conjured,
            }
        end
    end

    return bodies
end

-- Source zap data distributes the capped power-based damage maximum
-- across four dice with randomized rounding on the chosen saved stream.
function refrigeration.base_sides(ctx, power, stream)
    local maximum = BASE_MAXIMUM + math.floor(
        math.min(power, POWER_CAP) * POWER_NUMERATOR /
            POWER_DENOMINATOR)

    return roll.random_divide(ctx, maximum, DICE_COUNT, stream)
end

-- Count nearby nonconjured bodies from the precast snapshot, including
-- allies. The target itself never reduces its own die size.
function refrigeration.adjacent(snapshot, target)
    local position

    for _, body in ipairs(snapshot) do
        if body.entity == target then
            position = body.position
            break
        end
    end

    if not position then
        return 0
    end

    local count = 0

    for _, body in ipairs(snapshot) do
        if body.entity ~= target and not body.conjured and
            body.position.level_id == position.level_id and
            math.max(
                math.abs(body.position.x - position.x),
                math.abs(body.position.y - position.y)) <= 1 then
            count = count + 1
        end
    end

    return count
end

-- Apply source's one-body 2/3 or crowded 1/3 side reduction, then roll
-- four cold dice. This rule is shared by player and monster casts.
function refrigeration.raw_damage(ctx, base, adjacent, stream)
    local sides = base

    if adjacent == 1 then
        sides = roll.random_divide(ctx, 2 * base, 3, stream)
    elseif adjacent > 1 then
        sides = roll.random_divide(ctx, base, 3, stream)
    end

    local amount = DICE_COUNT

    for _ = 1, DICE_COUNT do
        amount = amount + ctx:random(stream, sides)
    end

    return amount
end

return refrigeration
