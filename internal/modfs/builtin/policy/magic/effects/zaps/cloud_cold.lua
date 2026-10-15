local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local player_health = require("policy.combat.player_health")
local roll = require("policy.combat.roll")

local cold = {}

function cold.apply(ctx, actor)
    -- cloud.cc:NORMAL_CLOUD_DAM, shared by fire and cold clouds.
    if actor == ctx:player() then
        local raw = 10 + roll.average_two(ctx, "spell", 23)
        local after_ac = damage.player_armour(ctx, actor, raw)
        local amount = damage.player_elemental(ctx, actor, after_ac,
            "MR_RES_COLD")

        if amount > 0 then
            player_health.damage(ctx, actor, amount)
            ctx:emit("spell", "You are chilled by the freezing vapour!")
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
        "MR_RES_COLD")

    if amount > 0 then
        damage.apply(ctx, actor, amount)
        ctx:emit("spell", "The " .. definition.name ..
            " freezes in the vapour!")
    end
end

return cold
