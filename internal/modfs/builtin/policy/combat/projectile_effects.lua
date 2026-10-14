local roll = require("policy.combat.roll")
local fighter = require("policy.combat.fighter")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local dispersal = require("policy.combat.dispersal")

local effects = {}

local function resistance(definition, id)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == id then
            return entry.level
        end
    end

    return 0
end

local function elemental_damage(raw, level)
    -- fight.cc:610-663: monster elemental resistance divides by 1 + r^2,
    -- reaches immunity at rF/rC 3, and vulnerability adds half damage.
    if level >= 3 then
        return 0
    end

    if level > 0 then
        return math.floor(raw / (1 + level * level))
    end

    if level < 0 then
        return math.floor(raw * 15 / 10)
    end

    return raw
end

function effects.launcher(ctx, brand, missile, defender, damage)
    if brand == "" or brand == "SPWPN_NORMAL" or damage <= 0 then
        return 0
    end

    if brand == "SPWPN_VORPAL" then
        -- attack.cc:1423 adds 1 + random2(damage_done) / 3.
        return 1 + math.floor(roll.melee(ctx, damage) / 3)
    end

    local element
    local verb

    if brand == "SPWPN_FLAMING" then
        element = "MR_RES_FIRE"
        verb = "burns"
    elseif brand == "SPWPN_FREEZING" then
        element = "MR_RES_COLD"
        verb = "freezes"
    else
        error("unsupported launcher brand " .. tostring(brand))
    end

    -- attack.cc:1599 rolls the elemental part after ordinary damage.
    local raw = 1 + math.floor(roll.melee(ctx, damage) / 2)
    local bonus = elemental_damage(raw, resistance(defender, element))

    if bonus == 0 then
        return 0
    end

    return bonus, "The " .. missile.name .. " " .. verb ..
        " the " .. defender.name .. "."
end

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
