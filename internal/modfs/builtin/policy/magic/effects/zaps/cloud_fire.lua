local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local resistances = require("constants.resistance_ids")
local player_health = require("policy.combat.player_health")
local causes = require("constants.damage_causes")
local roll = require("policy.combat.roll")

local fire = {}

function fire.apply(ctx, actor)
    -- cloud.cc:NORMAL_CLOUD_DAM: 6+r2a(16,2) for monsters and
    -- 10+r2a(23,2) for players, then normal AC and fire resistance.
    if actor == ctx:player() then
        if effects.sum(ctx, actor,
            capabilities.FIRE_CLOUD_IMMUNITY) > 0 then
            return
        end

        local raw = 10 + roll.average_two(ctx, "spell", 23)
        local after_ac = damage.player_armour(ctx, actor, raw)
        local amount = damage.player_elemental(ctx, actor, after_ac,
            resistances.FIRE)

        if amount > 0 then
            player_health.damage(ctx, actor, amount,
                false, nil, causes.CLOUD)
            ctx:emit("spell", "You are burned by the flames!")
        end

        return
    end

    local monster = ctx:get(actor, component.ACTOR)
    local health = ctx:get(actor, component.HEALTH)

    if not monster or not health or health.current <= 0 then
        return
    end

    local definition = catalog.get("monsters", monster.kind_id)
    local raw = 6 + roll.average_two(ctx, "spell", 16)
    local ac = defense.armour(ctx, actor, definition)
    local after_ac = math.max(0, raw - ctx:random("spell", ac + 1))
    local amount = damage.monster_elemental(ctx, actor, after_ac,
        resistances.FIRE)

    if amount > 0 then
        damage.apply(ctx, actor, amount)
        ctx:emit("spell", "The " .. definition.name .. " burns in the flames!")
    end
end

return fire
