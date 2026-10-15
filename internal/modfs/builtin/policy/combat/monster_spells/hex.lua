local resistance = require("policy.combat.player_resistance")
local stats = require("policy.combat.monster_stats")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local monster_health = require("policy.combat.monster_health")
local component = require("constants.component")

local hex = {}

-- Source: mon-cast.cc:mons_power_for_hd, beam.cc:ench_power_stepdown,
-- actor.cc:check_willpower. The two rolls intentionally use distinct bounds.
function hex.resisted(ctx, caster, player, definition)
    local power = stats.hit_dice(ctx, caster, definition) * 12
    local enchant_power = math.max(1, math.floor(power / 3))
    local adjusted = math.floor(35 * math.log(1 + enchant_power / 35) /
        math.log(2) + 0.5)
    local target = 100 + resistance.willpower(ctx, player) - adjusted
    local roll = ctx:random("monster_spell", 100) +
        ctx:random("monster_spell", 101)

    if target <= roll then
        return false
    end

    if levels.effective(ctx, player, mutations.MUT_DEMONIC_WILL) > 0 then
        local health = ctx:get(caster, component.HEALTH)

        if health and health.current > 0 then
            local rounded = math.floor(enchant_power / 10)
            local remainder = enchant_power % 10

            if remainder > 0 and ctx:random("monster_spell", 10) <
                remainder then
                rounded = rounded + 1
            end

            local amount = 3 + ctx:random("monster_spell", 1 + rounded)

            monster_health.damage(ctx, caster, amount, player)
            ctx:emit("combat", "Your will lashes out at the " ..
                definition.name .. "!")
        end
    end

    return true
end

return hex
