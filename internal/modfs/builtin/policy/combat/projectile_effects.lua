local roll = require("policy.combat.roll")
local fighter = require("policy.combat.fighter")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local dispersal = require("policy.combat.dispersal")

local effects = {}

function effects.missile(ctx, ego, missile, monster, defender, damage, remaining_hp)
    if missile.id == "MI_DART" then
        local power = fighter.skill(ctx, "SK_THROWING", 1)

        if ego == "poisoned" then
            damage = roll.melee(ctx, 3 + power * 2)
        elseif ego == "curare" then
            damage = 2
        else
            damage = 5 + roll.melee(ctx, power)
        end
    end

    if ego == "" then
        return 0
    end

    if ego == "poisoned" then
        local levels = 0

        if missile.id == "MI_DART" then
            -- ranged-attack.cc:536-556: player poison darts carry duration
            -- power rather than ordinary hit-point damage.
            levels = damage
        elseif roll.melee(ctx, 4) ~= 0 then
            levels = 6 + roll.melee(ctx, 8) +
                roll.melee(ctx, math.floor(damage * 3 / 2))
        end

        poison.apply(ctx, monster, defender, levels, ctx:player())

        return 0
    end

    if ego == "curare" then
        -- beam.cc:1862-1904 poisons, deals 2d6 asphyxiation damage, then
        -- slows a surviving non-resistant monster.
        if not poison.apply(ctx, monster, defender, 2, ctx:player()) then
            return 0
        end

        local extra = 2 + roll.melee(ctx, 6) + roll.melee(ctx, 6)
        ctx:emit("combat", "The " .. defender.name .. " convulses.")

        if remaining_hp > extra then
            slow.apply(ctx, monster, defender)
        end

        return extra
    end

    if ego == "dispersal" then
        if damage > 0 and remaining_hp > 0 then
            dispersal.blink(ctx, ctx:player(), monster, defender)
        end

        return 0
    end

    error("unsupported missile ego " .. tostring(ego))
end

return effects
