local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local melee = require("policy.combat.melee")
local practice = require("policy.combat.practice")

local actions = {}

local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function damage(ctx, target, amount, player_kill)
    local health = ctx:get(target, "core.health")

    if not health then
        error("combat target has no health")
    end

    local before = health.current
    health.current = math.max(0, health.current - amount)
    ctx:set(target, "core.health", health)

    if player_kill and before > 0 and health.current == 0 then
        ctx:signal("player_kill", target)
    end

    return health
end

function actions.player(ctx, target)
    local actor = ctx:get(target, "core.actor")

    if not actor then
        error("player melee target lacks actor")
    end

    local defender = catalog.get("monsters", actor.kind_id)
    local input = fighter.attack(ctx, defender)
    input.defender_ac = input.defender_ac + equipment.protection_ac(ctx, target)

    local outcome = melee.player(ctx, input)
    local health = damage(ctx, target, outcome.damage, true)
    local message = "You miss the " .. defender.name .. "."

    if outcome.kind == "hit" then
        practice.player_hit(ctx, input)
        message = "You hit the " .. defender.name .. "."

        if outcome.damage == 0 then
            message = "You hit the " .. defender.name .. " but do no damage."
        end
    end

    ctx:emit("combat", message)

    if health.current == 0 then
        return
    end

    local headbutt = melee.headbutt_input(ctx, defender)
    headbutt.defender_ac = headbutt.defender_ac + equipment.protection_ac(ctx, target)
    local auxiliary = melee.auxiliary_headbutt(ctx, headbutt)

    if not auxiliary.attempted then
        return
    end

    message = "Your headbutt misses the " .. defender.name .. "."

    if auxiliary.hit then
        damage(ctx, target, auxiliary.damage, true)
        message = "You headbutt the " .. defender.name .. "."

        if auxiliary.damage == 0 then
            message = "You headbutt the " .. defender.name .. ", but do no damage."
        end
    end

    ctx:emit("combat", message)
end

local function update_shield(ctx, outcome)
    local player = ctx:player()
    local state = ctx:get(player, "core.combat")

    if not state then
        error("player has no combat state")
    end

    state.shield_blocks = outcome.shield_blocks
    ctx:set(player, "core.combat", state)
end

local function retaliate(ctx, attacker, definition)
    local input = melee.headbutt_input(ctx, definition)
    input.defender_ac = input.defender_ac + equipment.protection_ac(ctx, attacker)
    local outcome = melee.reflexive_headbutt(ctx, input)

    if not outcome.attempted then
        return
    end

    damage(ctx, attacker, outcome.damage, true)
    ctx:emit("combat", "You furiously retaliate!")

    local message = "You headbutt the " .. definition.name .. "."

    if outcome.damage == 0 then
        message = "You headbutt the " .. definition.name .. ", but do no damage."
    end

    ctx:emit("combat", message)
end

local function retreat_bat(ctx, attacker, definition)
    if not has_flag(definition.flags, "M_BATTY") then
        return
    end

    local ai = ctx:get(attacker, "core.ai")

    if not ai then
        error("batty monster has no AI")
    end

    ai.behavior = "wander"
    ai.target_x = 0
    ai.target_y = 0
    ai.memory_until_aut = 0
    ai.bat_retreat_actions = math.max(2, math.floor(definition.speed / 10)) - 1
    ctx:set(attacker, "core.ai", ai)
end

local function grab(ctx, attacker, definition, player_health)
    local attack = definition.attacks[2]

    if not attack or attack.type_id ~= "AT_CONSTRICT" or
        player_health.current <= 0 or ctx:has(ctx:player(), "core.constricted") then
        return
    end

    local defense = fighter.defense(ctx)
    local outcome = melee.monster(ctx, {
        hd = definition.hd,
        damage = attack.damage,
        type_id = attack.type_id,
        flavour_id = attack.flavour_id,
    }, defense)

    update_shield(ctx, outcome)
    practice.incoming_melee(ctx, outcome, defense)

    if outcome.kind == "hit" then
        ctx:add(ctx:player(), "core.constricted", {
            by = attacker,
            escape_attempts = 0,
        })
        ctx:emit("combat", "The " .. definition.name .. " grabs you.")

        return
    end

    local messages = {
        miss = "The " .. definition.name .. " misses you with its grab.",
        dodge = "You dodge the " .. definition.name .. "'s grab.",
        block = "You block the " .. definition.name .. "'s grab.",
    }

    ctx:emit("combat", messages[outcome.kind])
end

function actions.monster(ctx, attacker)
    local actor = ctx:get(attacker, "core.actor")

    if not actor then
        error("monster melee attacker lacks actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local attack = definition.attacks[1]
    local defense = fighter.defense(ctx)
    local weapon = nil

    if attack.type_id == "AT_HIT" then
        weapon = equipment.monster_melee(ctx, attacker)

        if weapon then
            brands.check(weapon.brand)
        end
    end

    local outcome = melee.monster(ctx, {
        hd = definition.hd,
        damage = attack.damage,
        type_id = attack.type_id,
        flavour_id = attack.flavour_id,
        weapon = weapon,
    }, defense)

    update_shield(ctx, outcome)
    local player = ctx:player()
    local health = damage(ctx, player, outcome.damage, false)
    practice.incoming_melee(ctx, outcome, defense)

    local message = ""

    if outcome.kind == "miss" then
        message = "The " .. definition.name .. " misses you."
    elseif outcome.kind == "dodge" then
        message = "You dodge the " .. definition.name .. "'s attack."
    elseif outcome.kind == "block" then
        message = "You block the " .. definition.name .. "'s attack."
    elseif outcome.kind == "hit" then
        local verb = attack.type_id == "AT_HIT" and "hits" or "bites"

        if outcome.damage == 0 then
            message = "The " .. definition.name .. " " .. verb .. " you, but does no damage."
        else
            message = "The " .. definition.name .. " " .. verb .. " you for " .. outcome.damage .. " damage."
        end
    end

    ctx:emit("combat", message)

    if outcome.kind == "hit" and weapon and
        (health.current > 0 or brands.after_death(weapon.brand)) then
        brands.apply(ctx, weapon.brand, outcome.damage, actor.kind_id, definition.name, health)
        ctx:set(player, "core.health", health)
    end

    if outcome.kind == "miss" or outcome.kind == "dodge" then
        retaliate(ctx, attacker, definition)

        local attacker_health = ctx:get(attacker, "core.health")

        if not attacker_health or attacker_health.current <= 0 then
            return
        end
    end

    retreat_bat(ctx, attacker, definition)

    if outcome.kind == "hit" and attack.flavour_id == "AF_POISON" then
        brands.poison_bite(ctx, definition.hd, actor.kind_id)
    end

    grab(ctx, attacker, definition, health)
end

return actions
