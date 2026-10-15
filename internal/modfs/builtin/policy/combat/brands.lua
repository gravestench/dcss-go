local roll = require("policy.combat.roll")

local brands = {}

local function effect(id)
    if id == "" then
        id = "SPWPN_NORMAL"
    end

    local name = id:match("^SPWPN_([A-Z_]+)$")

    if not name then
        error("invalid weapon brand " .. tostring(id))
    end

    local module = require("policy.combat.brands." .. name:lower())

    if type(module) ~= "table" or type(module.apply) ~= "function" then
        error("weapon brand " .. id .. " has no apply function")
    end

    return module
end

function brands.check(id)
    effect(id)
end

function brands.after_death(id)
    return effect(id).after_death == true
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

function brands.apply(ctx, id, damage_done, source_id, attacker_name, health)
    local impact = {
        damage_done = damage_done,
        source_id = source_id,
        attacker_name = attacker_name,
        health = health,
        attacker = ctx:actor(),
        defender = ctx:player(),
    }

    effect(id).apply(ctx, impact, brands)
end

return brands
