local roll = require("policy.combat.roll")

local brands = {}

local supported = {
    [""] = true,
    SPWPN_NORMAL = true,
    SPWPN_PROTECTION = true,
    SPWPN_VENOM = true,
    SPWPN_FLAMING = true,
    SPWPN_FREEZING = true,
    SPWPN_ELECTROCUTION = true,
    SPWPN_VORPAL = true,
}

local after_death = {
    SPWPN_FLAMING = true,
    SPWPN_FREEZING = true,
    SPWPN_ELECTROCUTION = true,
}

function brands.check(brand)
    if not supported[brand or ""] then
        error("unsupported monster melee brand " .. tostring(brand))
    end
end

function brands.after_death(brand)
    return after_death[brand] or false
end

function brands.poison(ctx, amount, source_id)
    if amount <= 0 then
        return
    end

    local player = ctx:player()
    local poison = ctx:get(player, "core.poison")

    if poison then
        poison.amount_scaled = math.min(2147483647, poison.amount_scaled + amount * 1000)
        poison.source_monster_id = source_id
        ctx:set(player, "core.poison", poison)
    else
        ctx:add(player, "core.poison", {
            amount_scaled = amount * 1000,
            source_monster_id = source_id,
        })
    end

    ctx:emit("poison", "You are poisoned.")
end

function brands.poison_bite(ctx, hit_dice, source_id)
    if roll.melee(ctx, 3) ~= 0 then
        return
    end

    brands.poison(ctx, 2 * hit_dice + roll.melee(ctx, 2 * hit_dice + 1), source_id)
end

function brands.apply(ctx, brand, damage_done, source_id, attacker_name, health)
    brand = brand or ""
    brands.check(brand)

    if brand == "" or brand == "SPWPN_NORMAL" or brand == "SPWPN_PROTECTION" then
        return
    end

    if brand == "SPWPN_VENOM" then
        if roll.melee(ctx, 4) == 0 then
            return
        end

        local base = roll.melee(ctx, 8)
        local bonus = roll.melee(ctx, math.floor(damage_done * 3 / 2))
        brands.poison(ctx, 6 + base + bonus, source_id)

        return
    end

    local bonus = 0

    if brand == "SPWPN_FLAMING" or brand == "SPWPN_FREEZING" then
        if damage_done == 0 then
            return
        end

        bonus = 1 + math.floor(roll.melee(ctx, damage_done) / 2)
    elseif brand == "SPWPN_VORPAL" then
        if damage_done == 0 then
            return
        end

        bonus = 1 + math.floor(roll.melee(ctx, damage_done) / 3)
    elseif brand == "SPWPN_ELECTROCUTION" then
        if roll.melee(ctx, 4) ~= 0 then
            return
        end

        bonus = 8 + roll.melee(ctx, 13)
    end

    health.current = math.max(0, health.current - bonus)

    if bonus == 0 then
        return
    end

    if brand == "SPWPN_FLAMING" then
        ctx:emit("combat", "The " .. attacker_name .. " burns you.")
    elseif brand == "SPWPN_FREEZING" then
        ctx:emit("combat", "The " .. attacker_name .. " freezes you.")
    elseif brand == "SPWPN_ELECTROCUTION" then
        ctx:emit("combat", bonus >= 18 and "You are electrocuted!!" or "You are electrocuted!")
    end
end

return brands
