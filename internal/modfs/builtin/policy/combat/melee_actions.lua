local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local auxiliary = require("policy.combat.auxiliary")
local fighter = require("policy.combat.fighter")
local melee = require("policy.combat.melee")
local slime_blob = require("policy.monsters.slime_blob")
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
local monster_profile = require("policy.combat.monster_profile")
local attack_flavours = require("policy.combat.monster_attack_flavours")
local ignis_champion = require("policy.religion.wrath.ignis_champion")
local trample = require("policy.combat.trample")
local monster_roll = require("policy.combat.monster_roll")
local roll = require("policy.combat.roll")
local attack_types = require("constants.monster_attack_types")
local weapon_brands = require("constants.weapon_brands")
local stab = require("policy.combat.stab")
local vampire = require("policy.character.vampire")
local auxiliary_attacks = require("constants.auxiliary_attacks")
local target_brands = require("policy.combat.monster_target_brands")
local player_staves = require("policy.combat.player_staves")
local boons = require("policy.combat.monster_support.boons")
local black_mark = require("policy.combat.monster_black_mark")
local brambles = require("policy.combat.monster_plants.brambles")
local vine_grip = require("policy.combat.monster_plants.vine_grip")
local component = require("constants.component")
local attack_conduct = require("policy.religion.conduct.attack")
local cleaving = require("policy.religion.xom.cleaving")
local attack_sequence = require("policy.combat.monster_attack_sequence")
local reach = require("policy.combat.monster_reach")

local actions = {}

-- These entry points coordinate a full monster attack round. The smaller
-- combat policies calculate each contact, brand, and reaction; this module
-- orders them so death and displacement stop later contacts.

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

    return health, dealt
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
local function player_contact(ctx, target, options)
    local actor = ctx:get(target, "core.actor")

    if not actor then
        error("player melee target lacks actor")
    end

    local defender = monster_profile.definition(ctx, target,
        catalog.get("monsters", actor.kind_id))

    attack_conduct.report(ctx, target, defender)

    rage.melee(ctx, ctx:player())
    mutation_effects.trigger(ctx, ctx:player(),
        mutation_capabilities.ON_MELEE_ATTEMPT, {
            target = target,
        })

    local input = fighter.attack(ctx, defender)
    input.stab_target = target
    input.roll_distance = options and options.roll_distance or 0
    input.cleave_secondary = options and options.cleave_secondary or false
    input.defender_ev = monster_defense.evasion(ctx, target, defender)
    input.defender_ac = monster_defense.armour(ctx, target, defender)
    input.defender_shield = monster_defense.shield(ctx, target, defender)

    local outcome = melee.player(ctx, input)

    brambles.thorns(ctx, ctx:player(), target,
        outcome.kind == "block")

    if ctx:get(ctx:player(), component.HEALTH).current <= 0 then
        return
    end

    local health, actual_dealt = damage(ctx, target, outcome.damage, true)
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
        damage_done = actual_dealt,
        health = health,
        weapon_id = input.weapon_id,
        weapon_entity = input.weapon_entity,
    }

    if outcome.kind == "hit" then
        target_brands.apply(ctx, input.weapon_brand, hit)
        local weapon = input.weapon_id and catalog.get("items", input.weapon_id)

        player_staves.apply(ctx, hit, target_brands, weapon,
            input.defender_ac)
        health = hit.health

        if not hit.banished and not hit.moved then
            statuses.confusing_touch_contact(ctx, ctx:player(), target,
                defender)
        end
    end

    target_brands.after_attack(ctx, input.weapon_brand, hit)

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

    -- Source secondary cleaves use an ordinary contact but do not generate
    -- auxiliary attacks of their own.
    if input.cleave_secondary then
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

-- Capture other targets before the primary hit can kill or move its victim.
-- Resolve those saved targets after the complete primary contact, including
-- its brands and auxiliary strikes. A secondary call cannot cleave again.
function actions.player(ctx, target, options)
    local secondary = {}

    if not (options and options.cleave_secondary) and
        cleaving.active(ctx, ctx:player()) then
        secondary = cleaving.targets(ctx, ctx:player(), target)
    end

    player_contact(ctx, target, options)

    for _, victim in ipairs(secondary) do
        local player_health_state = ctx:get(ctx:player(), component.HEALTH)
        local health = ctx:get(victim, component.HEALTH)
        local origin = ctx:get(ctx:player(), component.POSITION)
        local position = ctx:get(victim, component.POSITION)

        if not player_health_state or player_health_state.current <= 0 then
            break
        end

        if health and health.current > 0 and origin and position and
            origin.level_id == position.level_id and
            math.max(math.abs(origin.x - position.x),
                math.abs(origin.y - position.y)) == 1 and
            targets.enemy(ctx, ctx:player(), victim) then
            player_contact(ctx, victim, {
                cleave_secondary = true,
            })
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

-- A constricting slot starts a saved hold only after a living victim
-- survives the slot's own hit roll; it is not a bonus after the round.
local function grab(ctx, attacker, definition, attack, player_health)
    if player_health.current <= 0 or
        ctx:has(ctx:player(), "core.constricted") then
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
local function monster_player_contact(ctx, attacker, selected,
    contact_index, options)
    local player_moving = options and options.player_moving or false
    local actor = ctx:get(attacker, "core.actor")

    if not actor then
        error("monster melee attacker lacks actor")
    end

    local definition = monster_profile.definition(ctx, attacker,
        catalog.get("monsters", actor.kind_id))
    local attack = selected.attack
    local flavour_id = ignis_champion.attack_flavour(ctx, attacker,
        attack.flavour_id)
    local attack_type = monster_roll.active(ctx, attacker) and
        attack_types.HIT or attack_sequence.contact_type(ctx, attack)
    local defense = fighter.defense(ctx)
    local weapon = nil

    if attack_type == attack_types.HIT then
        weapon = equipment.monster_melee(ctx, attacker,
            contact_index)

        if weapon then
            brands.check(weapon.brand)
        end
    end

    local attack_input = {
        attacker = attacker,
        hd = monster_stats.hit_dice(ctx, attacker, definition),
        damage = monster_roll.attack_damage(ctx, attacker,
            slime_blob.attack_damage(ctx, attacker, attack.damage)),
        type_id = attack_type,
        flavour_id = flavour_id,
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
        local verb = attack_type == attack_types.HIT and "hits" or "bites"

        if dealt == 0 then
            message = "The " .. definition.name .. " " .. verb .. " you, but does no damage."
        else
            message = "The " .. definition.name .. " " .. verb .. " you for " .. dealt .. " damage."
        end
    end

    ctx:emit("combat", message)

    local illusion = ctx:get(attacker, component.PLAYER_ILLUSION)
    local lord = ctx:get(attacker, component.PANDEMONIUM_LORD)
    local lord_brand = lord and lord.brand_id ~= weapon_brands.NORMAL and
        lord.brand_id
    local brand_id = weapon and weapon.brand or
        illusion and illusion.brand_id or lord_brand

    if outcome.kind == "hit" and brand_id and
        (health.current > 0 or brands.after_death(brand_id)) then
        brands.apply(ctx, brand_id, outcome.damage,
            actor.kind_id, definition.name, health,
            attacker, player_moving)
    end

    local flavour_hit

    if outcome.kind == "hit" then
        flavour_hit = {
            kind = outcome.kind,
            attacker = attacker,
            attacker_name = definition.name,
            defender = player,
            hit_dice = attack_input.hd,
            damage_done = dealt,
            player_moving = player_moving,
        }

        attack_flavours.apply(ctx, flavour_id, flavour_hit)
    end

    if outcome.kind == "hit" and dealt > 0 then
        black_mark.after_melee(ctx, attacker, player, dealt)
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

    -- Poison-bearing contact needs physical damage through armour before
    -- either ordinary venom or concentrated curare can enter the wound.
    if outcome.kind == "hit" and dealt > 0 and
        (flavour_id == "AF_POISON" or
        flavour_id == "AF_POISON_STRONG" or
        flavour_id == "AF_REACH_STING") then
        local venom = require("policy.combat.monster_tactical.concentrate_venom")
        local dice = monster_stats.hit_dice(ctx, attacker, definition)

        if venom.active(ctx, attacker) then
            -- melee-attack.cc gates all three poison flavours at one in
            -- three before Concentrate Venom changes the dose to curare.
            if roll.melee(ctx, 3) == 0 then
                require("policy.combat.monster_tactical.curare")
                    .apply(ctx, attacker, player, "melee")
            end
        elseif flavour_id == "AF_POISON_STRONG" then
            if roll.melee(ctx, 3) == 0 then
                local low = math.floor(dice * 11 / 3)
                local high = math.floor(dice * 13 / 2)

                brands.poison(ctx, low + roll.melee(ctx, high - low + 1),
                    actor.kind_id)
            end
        else
            brands.poison_bite(ctx, dice, actor.kind_id)
        end
    end

    player_reactions.after_attack(ctx, attacker, definition)
    trample.follow(ctx, flavour_hit)
end

-- Confusion and allegiance can make another monster the target. Validate
-- that relationship before resolving combat so ordinary allies cannot be
-- attacked through this API by accident.
local function monster_target_contact(ctx, attacker, target,
    selected, contact_index)
    local attacker_actor = ctx:get(attacker, "core.actor")
    local target_actor = ctx:get(target, "core.actor")

    if not attacker_actor or not target_actor then
        error("monster melee requires two actors")
    end

    local attacker_def = monster_profile.definition(ctx, attacker,
        catalog.get("monsters", attacker_actor.kind_id))
    local target_def = monster_profile.definition(ctx, target,
        catalog.get("monsters", target_actor.kind_id))
    local attack = selected.attack

    if not attack or attack.type_id == "AT_NONE" then
        return
    end

    local flavour_id = ignis_champion.attack_flavour(ctx, attacker,
        attack.flavour_id)

    local attack_type = monster_roll.active(ctx, attacker) and
        attack_types.HIT or attack_sequence.contact_type(ctx, attack)
    local summon_stats = ctx:get(attacker, "magic.summon_stats")
    local weapon = nil

    -- Natural attacks cannot transmit a brand from an item merely held by
    -- the monster. This matches the monster-against-player contact path.
    if attack_type == attack_types.HIT then
        weapon = equipment.monster_melee(ctx, attacker,
            contact_index)
    end
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
        damage = monster_roll.attack_damage(ctx, attacker,
            slime_blob.attack_damage(ctx, attacker, attack.damage)),
        type_id = attack_type,
        flavour_id = flavour_id,
        weapon = weapon,
    }, defense)

    brambles.thorns(ctx, attacker, target,
        outcome.kind == "block")

    if ctx:get(attacker, component.HEALTH).current <= 0 then
        return
    end

    if combat then
        combat.shield_blocks = outcome.shield_blocks
        ctx:set(target, "core.combat", combat)
    end

    local dealt = statuses.frenzy_melee_damage(ctx, attacker,
        outcome.damage)
    dealt = boons.damage(ctx, attacker, dealt)
    local health, actual_dealt = damage(ctx, target, dealt,
        targets.allied(ctx, attacker) or statuses.frenzied(ctx, attacker),
        attacker)

    if outcome.kind == "hit" and actual_dealt > 0 then
        black_mark.after_melee(ctx, attacker, target, actual_dealt)
        health = ctx:get(target, "core.health")
    end

    local illusion = ctx:get(attacker, component.PLAYER_ILLUSION)
    local lord = ctx:get(attacker, component.PANDEMONIUM_LORD)
    local lord_brand = lord and lord.brand_id ~= weapon_brands.NORMAL and
        lord.brand_id
    local brand_id = weapon and weapon.brand or
        attack_type == attack_types.HIT and illusion and
        illusion.brand_id or lord_brand

    if outcome.kind == "hit" and brand_id then
        local hit = {
            attacker = attacker,
            attacker_name = attacker_def.name,
            defender = target,
            definition = target_def,
            damage_done = actual_dealt,
            health = health,
            weapon_entity = weapon and weapon.entity,
            player_credit = targets.allied(ctx, attacker) or
                statuses.frenzied(ctx, attacker),
        }

        target_brands.apply(ctx, brand_id, hit)
        health = hit.health
    end

    local flavour_hit

    if outcome.kind == "hit" then
        flavour_hit = {
            kind = outcome.kind,
            attacker = attacker,
            attacker_name = attacker_def.name,
            defender = target,
            defender_definition = target_def,
            hit_dice = monster_stats.hit_dice(ctx, attacker, attacker_def),
            damage_done = actual_dealt,
            player_credit = targets.allied(ctx, attacker) or
                statuses.frenzied(ctx, attacker),
        }

        attack_flavours.apply(ctx, flavour_id, flavour_hit)

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

    trample.follow(ctx, flavour_hit)

    return health
end

-- Source hydras prefer an adjacent hostile player, then another living
-- monster. Search positions, not a cached target list, after each head.
local function adjacent_enemy(ctx, attacker, lost)
    local origin = ctx:get(attacker, component.POSITION)

    if not origin then
        return nil
    end

    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)
    local player_health_state = ctx:get(player, component.HEALTH)

    if player ~= lost and player_position and player_health_state and
        player_health_state.current > 0 and
        player_position.level_id == origin.level_id and
        math.max(math.abs(player_position.x - origin.x),
            math.abs(player_position.y - origin.y)) == 1 and
        targets.enemy(ctx, attacker, player) then
        return player
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local candidate = ctx:actor_at(origin.level_id,
                    origin.x + dx, origin.y + dy)
                local health = candidate and ctx:get(candidate,
                    component.HEALTH)

                if candidate and candidate ~= attacker and
                    candidate ~= lost and health and
                    health.current > 0 and
                    targets.enemy(ctx, attacker, candidate) then
                    return candidate
                end
            end
        end
    end

    return nil
end

-- Source melee spends one action on every live slot. When the current
-- defender dies or moves, only living hydras and Serpents may pick another
-- adjacent enemy. Both public entry points share this round boundary.
local function run_round(ctx, attacker, target, options)
    local actor = ctx:get(attacker, component.ACTOR)

    if not actor then
        error("monster melee attacker lacks actor")
    end

    local definition = monster_profile.definition(ctx, attacker,
        catalog.get("monsters", actor.kind_id))
    local contacts = attack_sequence.for_actor(ctx, attacker, definition)
    local origin = ctx:get(target, component.POSITION)
    local last_health
    local effective_index = 0

    for _, selected in ipairs(contacts) do
        local attacker_health = ctx:get(attacker, component.HEALTH)
        local defender_health = ctx:get(target, component.HEALTH)
        local position = ctx:get(target, component.POSITION)

        if not attacker_health or attacker_health.current <= 0 then
            break
        end

        local lost = not defender_health or
            defender_health.current <= 0 or not origin or not position or
            position.level_id ~= origin.level_id or
            position.x ~= origin.x or position.y ~= origin.y

        if lost then
            if not attack_sequence.can_retarget(definition) then
                break
            end

            target = adjacent_enemy(ctx, attacker, target)

            if not target then
                break
            end

            origin = ctx:get(target, component.POSITION)
            defender_health = ctx:get(target, component.HEALTH)
        end

        local attacker_position = ctx:get(attacker, component.POSITION)
        local target_position = ctx:get(target, component.POSITION)
        local distance = math.max(
            math.abs(attacker_position.x - target_position.x),
            math.abs(attacker_position.y - target_position.y))

        -- Source skips each ordinary slot independently when the foe is
        -- beyond adjacency; the later Sting slot retains its source index.
        if distance <= 1 or reach.contact(ctx, attacker,
            selected.attack, effective_index + 1, distance) then
            -- Source skipped attempts do not advance the weapon hand.
            -- A dual wielder's next eligible slot reuses that hand.
            effective_index = effective_index + 1

            if target == ctx:player() then
                if selected.attack.type_id == attack_types.CONSTRICT then
                    if not (options and options.player_moving) then
                        grab(ctx, attacker, definition,
                            selected.attack, defender_health)
                    end
                else
                    monster_player_contact(ctx, attacker, selected,
                        effective_index, options)
                end

                last_health = ctx:get(target, component.HEALTH)
            else
                last_health = monster_target_contact(ctx, attacker,
                    target, selected, effective_index)
            end
        end
    end

    return last_health
end

-- The player's current enemy uses the same ordered round as monster versus
-- monster combat; contact resolution still reads the player's real ECS data.
function actions.monster(ctx, attacker, options)
    if ctx:has(attacker, component.MONSTER_VINE) then
        vine_grip.contact(ctx, attacker, ctx:player())

        return
    end

    return run_round(ctx, attacker, ctx:player(), options)
end

-- Confusion can authorize a monster target outside normal allegiance. The
-- special summon and vine attacks own their single contact before the
-- ordinary catalog sequence is considered.
function actions.monster_target(ctx, attacker, target)
    if not targets.enemy(ctx, attacker, target) and
        not confusion.active(ctx, attacker) then
        error("monster cannot attack an allied actor")
    end

    if ctx:has(attacker, component.MONSTER_VINE) then
        vine_grip.contact(ctx, attacker, target)

        return
    end

    if summon_melee.attack(ctx, attacker, target) then
        if ctx:has(target, component.ACTOR) then
            brambles.thorns(ctx, attacker, target, false)
        end

        return
    end

    return run_round(ctx, attacker, target)
end

return actions
