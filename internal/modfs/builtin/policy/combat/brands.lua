local roll = require("policy.combat.roll")

local brands = {}

-- The SPWPN id is validated before loading its effect, so a missing brand cannot silently become normal.
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

-- Example: brands.check(id) with unknown weapon brand ID -> validation error
-- Resolve the brand module now so an unknown ego fails before it reaches an attack.
function brands.check(id)
    effect(id)
end

-- Some brand effects may run after lethal base damage; consult the module flag.
function brands.after_death(id)
    return effect(id).after_death == true
end

-- Poison is stored in thousandths to preserve fractional accumulation across later ticks.
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

-- A venomous bite adds poison on three of four melee-stream rolls, scaled by attacker hit dice.
function brands.poison_bite(ctx, hit_dice, source_id)
    if roll.melee(ctx, 3) ~= 0 then
        return
    end

    brands.poison(ctx, 2 * hit_dice + roll.melee(ctx, 2 * hit_dice + 1), source_id)
end

-- Build one hit envelope so every monster brand sees the same attacker and defender state.
function brands.apply(ctx, id, damage_done, source_id, attacker_name,
    health, attacker, player_moving)
    local impact = {
        damage_done = damage_done,
        source_id = source_id,
        attacker_name = attacker_name,
        health = health,
        attacker = attacker or ctx:actor(),
        defender = ctx:player(),
        player_moving = player_moving or false,
    }

    effect(id).apply(ctx, impact, brands)
end

return brands
