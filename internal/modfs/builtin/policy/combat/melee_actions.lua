local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local auxiliary = require("policy.combat.auxiliary")
local fighter = require("policy.combat.fighter")
local melee = require("policy.combat.melee")
local practice = require("policy.combat.practice")
local player_health = require("policy.combat.player_health")
local statuses = require("policy.magic.effects.statuses.player")
local targets = require("policy.ai.targets")
local summon_melee = require("policy.combat.summon_melee")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local monster_defense = require("policy.combat.monster_defense")
local player_reactions = require("policy.combat.player_reactions")
local engulf = require("policy.combat.engulf")
local monster_health = require("policy.combat.monster_health")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local rage = require("policy.character.rage")
local monster_stats = require("policy.combat.monster_stats")
local stab = require("policy.combat.stab")
local vampire = require("policy.character.vampire")
local auxiliary_attacks = require("constants.auxiliary_attacks")
local player_brands = require("policy.combat.player_brands")
local player_staves = require("policy.combat.player_staves")
local boons = require("policy.combat.monster_support.boons")

local actions = {}

-- These entry points coordinate one contact. The smaller combat policies
-- calculate hit, damage, brands and reactions; this module orders them so
-- on-hit effects see the actual outcome and death stops later contacts.

-- Read monster flags for attack-specific movement and immunity decisions.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Vampire stab blood draw requires adjacent contact on the same level, including diagonal contact.
local function player_adjacent_to(ctx, target)
    local player = ctx:get(ctx:player(), "core.position")
    local monster = ctx:get(target, "core.position")

    return player and monster and player.level_id == monster.level_id and
        math.max(math.abs(player.x - monster.x),
            math.abs(player.y - monster.y)) == 1
end

-- Player kills signal only after positive dealt damage reaches zero HP; both sides use their health policy.
local function damage(ctx, target, amount, player_kill, attacker)
    if target == ctx:player() then
        return player_health.damage(ctx, target, amount, false, attacker)
    end

    local health, dealt = monster_health.damage(ctx, target, amount,
        attacker or ctx:player())

    if player_kill and dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", target)
    end

    return health
end

-- Mutation follow-ups trigger only for a living target after positive melee damage.
local function after_player_melee_hit(ctx, target, amount, health)
    if amount <= 0 or health.current <= 0 then
        return
    end

    local hit = {
        target = target,
        damage = amount,
    }

    mutation_effects.trigger(ctx, ctx:player(),
        mutation_capabilities.AFTER_MELEE_HIT, hit)
end

-- A player attack first builds an attack from current gear and target stats,
-- then resolves hit and damage. Brand and mutation callbacks only run at
-- their corresponding contact phase; this order matters for DCSS effects.
function actions.player(ctx, target, options)
    local actor = ctx:get(target, "core.actor")

    if not actor then
        error("player melee target lacks actor")
    end

    local defender = catalog.get("monsters", actor.kind_id)

    rage.melee(ctx, ctx:player())
    mutation_effects.trigger(ctx, ctx:player(),
        mutation_capabilities.ON_MELEE_ATTEMPT, {
            target = target,
        })

    local input = fighter.attack(ctx, defender)
    input.stab_target = target
    input.roll_distance = options and options.roll_distance or 0
    input.defender_ev = monster_defense.evasion(ctx, target, defender)
    input.defender_ac = monster_defense.armour(ctx, target, defender)
    input.defender_shield = monster_defense.shield(ctx, target, defender)

    local outcome = melee.player(ctx, input)
    local health = damage(ctx, target, outcome.damage, true)
    local message = "You miss the " .. defender.name .. "."
    local blood_drawn = false

    if outcome.kind == "hit" and input.stab_plan and
        input.stab_plan.bonus > 0 and player_adjacent_to(ctx, target) then
        blood_drawn = vampire.draw_blood(ctx, ctx:player(), target,
            defender, outcome.damage)
    end

    if outcome.kind == "hit" and input.stab_plan and
        input.stab_plan.bonus > 0 then
        ctx:emit("combat", stab.message(ctx, ctx:player(),
            input.stab_plan, defender.name))
    end

    if outcome.kind == "hit" then
        practice.player_hit(ctx, input)
        message = "You hit the " .. defender.name .. "."

        if outcome.damage == 0 then
            message = "You hit the " .. defender.name .. " but do no damage."
        end
    elseif outcome.kind == "block" then
        monster_defense.register_block(ctx, target)
        message = "The " .. defender.name .. " blocks your attack."
    end

    ctx:emit("combat", message)

    local hit = {
        attacker = ctx:player(),
        defender = target,
        definition = defender,
        damage_done = outcome.damage,
        health = health,
        weapon_id = input.weapon_id,
        weapon_entity = input.weapon_entity,
    }

    if outcome.kind == "hit" then
        player_brands.apply(ctx, input.weapon_brand, hit)
        local weapon = input.weapon_id and catalog.get("items", input.weapon_id)

        player_staves.apply(ctx, hit, player_brands, weapon,
            input.defender_ac)
        health = hit.health

        if not hit.banished and not hit.moved then
            statuses.confusing_touch_contact(ctx, ctx:player(), target,
                defender)
        end
    end

    player_brands.after_attack(ctx, input.weapon_brand, hit)

    if health.current == 0 then
        return
    end

    if outcome.kind == "hit" and outcome.damage > 0 then
        after_player_melee_hit(ctx, target, outcome.damage, health)
        health = ctx:get(target, "core.health")

        if health.current > 0 and not hit.banished and not hit.moved then
            engulf.on_player_hit(ctx, target, outcome.damage)
        end
    end

    if hit.banished or hit.moved then
        return
    end

    local auxiliary_input = auxiliary.input(ctx, target, defender)
    auxiliary_input.defender_ev = monster_defense.evasion(ctx, target,
        defender)
    auxiliary_input.defender_ac = monster_defense.armour(ctx, target,
        defender)
    auxiliary_input.defender_shield = monster_defense.shield(ctx, target,
        defender)

    for _, attack in ipairs(auxiliary.all()) do
        if health.current <= 0 then
            break
        end

        local result = auxiliary.resolve_one(ctx, auxiliary_input, attack)

        if result.attempted then
            message = "Your " .. result.name .. " misses the " ..
                defender.name .. "."

            if result.blocked then
                local blocks = monster_defense.register_block(ctx, target)

                auxiliary_input.defender_shield.blocks = blocks
                message = "The " .. defender.name .. " blocks your " ..
                    result.name .. "."
            elseif result.hit then
                health = damage(ctx, target, result.damage, true)
                message = "You " .. result.verb .. " the " ..
                    defender.name .. "."

                if attack.id == auxiliary_attacks.BITE.id and
                    not blood_drawn then
                    vampire.draw_blood(ctx, ctx:player(), target,
                        defender, result.damage)
                end

                if result.damage == 0 and not attack.contact_only then
                    message = "You " .. result.verb .. " the " .. defender.name ..
                        ", but do no damage."
                end

                if health.current > 0 and attack.on_hit then
                    local extra = attack.on_hit(ctx, target, defender,
                        result) or 0

                    if extra > 0 then
                        health = damage(ctx, target, extra, true)
                    end
                end

                if result.damage > 0 then
                    after_player_melee_hit(ctx, target, result.damage, health)
                    health = ctx:get(target, "core.health")
                end
            end

            ctx:emit("combat", message)
        end
    end
end

-- Persist block count before a later monster attack can alter shield odds.
local function update_shield(ctx, outcome)
    local player = ctx:player()
    local state = ctx:get(player, "core.combat")

    if not state then
        error("player has no combat state")
    end

    state.shield_blocks = outcome.shield_blocks
    ctx:set(player, "core.combat", state)
end

-- Batty monsters forget the target and pause before re-engaging after a melee pass.
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

-- The second attack slot can start constriction only after the victim survives and is not already held.
local function grab(ctx, attacker, definition, player_health)
    local attack = definition.attacks[2]

    if not attack or attack.type_id ~= "AT_CONSTRICT" or
        player_health.current <= 0 or ctx:has(ctx:player(), "core.constricted") then
        return
    end

    local defense = fighter.defense(ctx)
    local outcome = melee.monster(ctx, {
        attacker = attacker,
        hd = monster_stats.hit_dice(ctx, attacker, definition),
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

-- Example: actions.monster(ctx, attacker) with monster adjacent to player -> melee outcome against player defense
-- A monster attacking the player uses player defense and reaction phases.
-- The monster-to-monster path below has different allegiance and summon
-- handling, so it has a separate entry point.
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

    local attack_input = {
        attacker = attacker,
        hd = monster_stats.hit_dice(ctx, attacker, definition),
        damage = attack.damage,
        type_id = attack.type_id,
        flavour_id = attack.flavour_id,
        weapon = weapon,
    }
    local outcome = melee.monster_contact(ctx, attack_input, defense)

    update_shield(ctx, outcome)

    if outcome.kind ~= "block" and
        not player_reactions.before_contact(ctx, attacker, definition) then
        return
    end

    if outcome.kind == "hit" then
        outcome.damage = melee.monster_damage(ctx, attack_input, defense)
        outcome.damage = statuses.frenzy_melee_damage(ctx, attacker,
            outcome.damage)
        outcome.damage = boons.damage(ctx, attacker, outcome.damage)
    end

    local player = ctx:player()
    local health, dealt = damage(ctx, player, outcome.damage, false,
        attacker)
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

        if dealt == 0 then
            message = "The " .. definition.name .. " " .. verb .. " you, but does no damage."
        else
            message = "The " .. definition.name .. " " .. verb .. " you for " .. dealt .. " damage."
        end
    end

    ctx:emit("combat", message)

    if outcome.kind == "hit" and weapon and
        (health.current > 0 or brands.after_death(weapon.brand)) then
        brands.apply(ctx, weapon.brand, outcome.damage, actor.kind_id, definition.name, health)
    end

    if outcome.kind == "hit" and not player_reactions.after_hit(ctx,
        attacker, definition, dealt) then
        return
    end

    if outcome.kind == "miss" or outcome.kind == "dodge" then
        if not player_reactions.after_miss(ctx, attacker, definition) then
            return
        end
    end

    retreat_bat(ctx, attacker, definition)

    if outcome.kind == "hit" and attack.flavour_id == "AF_POISON" then
        brands.poison_bite(ctx,
            monster_stats.hit_dice(ctx, attacker, definition),
            actor.kind_id)
    end

    grab(ctx, attacker, definition, ctx:get(player, "core.health"))
    player_reactions.after_attack(ctx, attacker, definition)
end

-- Confusion and allegiance can make another monster the target. Validate
-- that relationship before resolving combat so ordinary allies cannot be
-- attacked through this API by accident.
function actions.monster_target(ctx, attacker, target)
    if not targets.enemy(ctx, attacker, target) and
        not confusion.active(ctx, attacker) then
        error("monster cannot attack an allied actor")
    end

    local attacker_actor = ctx:get(attacker, "core.actor")
    local target_actor = ctx:get(target, "core.actor")

    if not attacker_actor or not target_actor then
        error("monster melee requires two actors")
    end

    if summon_melee.attack(ctx, attacker, target) then
        return
    end

    local attacker_def = catalog.get("monsters", attacker_actor.kind_id)
    local target_def = catalog.get("monsters", target_actor.kind_id)
    local attack = attacker_def.attacks[1]

    if not attack or attack.type_id == "AT_NONE" then
        return
    end

    local summon_stats = ctx:get(attacker, "magic.summon_stats")
    local weapon = equipment.monster_melee(ctx, attacker)
    local combat = ctx:get(target, "core.combat")
    local defense = {
        ev = monster_defense.evasion(ctx, target, target_def),
        ac = monster_defense.armour(ctx, target, target_def),
        gdr = 0,
        shield_class = 0,
        shield_blocks = combat and combat.shield_blocks or 0,
    }
    local outcome = melee.monster(ctx, {
        attacker = attacker,
        hd = monster_stats.hit_dice(ctx, attacker, attacker_def,
            summon_stats and summon_stats.hd or nil),
        damage = attack.damage,
        type_id = attack.type_id,
        flavour_id = attack.flavour_id,
        weapon = weapon,
    }, defense)

    if combat then
        combat.shield_blocks = outcome.shield_blocks
        ctx:set(target, "core.combat", combat)
    end

    local dealt = statuses.frenzy_melee_damage(ctx, attacker,
        outcome.damage)
    dealt = boons.damage(ctx, attacker, dealt)
    local health = damage(ctx, target, dealt,
        targets.allied(ctx, attacker) or statuses.frenzied(ctx, attacker),
        attacker)

    if outcome.kind == "hit" then
        ctx:emit("combat", "The " .. attacker_def.name .. " hits the " ..
            target_def.name .. " for " .. dealt .. " damage.")
    elseif outcome.kind == "block" then
        ctx:emit("combat", "The " .. target_def.name .. " blocks the " ..
            attacker_def.name .. ".")
    elseif outcome.kind == "dodge" then
        ctx:emit("combat", "The " .. target_def.name .. " dodges the " ..
            attacker_def.name .. ".")
    else
        ctx:emit("combat", "The " .. attacker_def.name .. " misses the " ..
            target_def.name .. ".")
    end

    return health
end

return actions
