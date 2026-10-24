local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local attack_conduct = require("policy.religion.conduct.attack")

local hailstorm = {}

-- Use Chebyshev distance so diagonals and cardinals share the same ring limit.
local function distance(source, target)
    return math.max(math.abs(target.x - source.x),
        math.abs(target.y - source.y))
end

-- Hailstorm excludes the caster's near cells and checks the annulus for a
-- visible target before allowing the cast.
local function in_ring(ctx, source, target, reach)
    return target.level_id == source.level_id and
        distance(source, target) > 1 and
        distance(source, target) <= reach and
        ctx:visible(source.level_id, source.x, source.y, reach,
            target.x, target.y)
end

-- Require an eligible monster in the outer hail ring before allowing a known cast.
function hailstorm.can_target(ctx, player, spell)
    local source = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)

            if health.current > 0 and in_ring(ctx, source, location, reach) then
                return true
            end
        end
    end

    return false
end

-- Random rounding sets die size before the three spell-stream damage dice.
local function roll_damage(ctx, power)
    -- zap-data.h:ZAP_HAILSTORM uses calcdice<3,10,1,2>.
    local maximum = 10 + math.floor(math.min(power, 100) / 2)
    local sides = math.floor(maximum / 3)
    local remainder = maximum % 3

    if remainder > 0 and ctx:random("spell", 3) < remainder then
        sides = sides + 1
    end

    local rolled = 0

    for _ = 1, 3 do
        rolled = rolled + 1 + ctx:random("spell", sides)
    end

    return rolled
end

-- Leave sixty percent of ice damage outside cold resistance per the source rule.
local function cold_damage(ctx, target, raw)
    -- fight.cc:BEAM_ICE leaves 60% irresistible to cold resistance.
    local resistible = math.floor(raw * 40 / 100)

    return raw - resistible +
        damage.monster_elemental(ctx, target, resistible,
            "MR_RES_COLD")
end

-- Example: resolve(ctx, player, nil, spell, 60) damages monsters in the ring
-- after their armour and cold resistance, leaving adjacent actors untouched.
-- Use the same outer-ring predicate as target preview, then roll each victim’s armour and partial cold resistance.
function hailstorm.resolve(ctx, player, _, spell, power)
    local source = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    ctx:emit("spell", "A cannonade of hail descends around you!")

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local definition, health = damage.monster(ctx, target)

            if health.current > 0 and in_ring(ctx, source, location, reach) then
                attack_conduct.report(ctx, target, definition)
                local ac = defense.armour(ctx, target, definition)
                local raw = roll_damage(ctx, power)
                local after_ac = math.max(0, raw - ctx:random("spell", ac + 1))
                local amount = cold_damage(ctx, target, after_ac)

                damage.apply(ctx, target, amount)
                ctx:emit("spell", "The hail pelts the " .. definition.name .. ".")
            end
        end
    end
end

registry.add(spells.SPELL_HAILSTORM, hailstorm)

return hailstorm
