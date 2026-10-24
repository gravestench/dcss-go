local monsters = require("ids.monsters")
local component = require("constants.component")
local weapon_brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local defense = require("policy.combat.monster_defense")
local melee = require("policy.combat.melee")
local magic_damage = require("policy.magic.damage")
local armour = require("policy.magic.effects.summons.animate_armour")
local monster_health = require("policy.combat.monster_health")
local monster_stats = require("policy.combat.monster_stats")
local monster_profile = require("policy.combat.monster_profile")
local target_brands = require("policy.combat.monster_target_brands")
local targets = require("policy.ai.targets")

local summon_melee = {}

-- Inherit base monster attacks for undead summons, with simulacra adding their icy contact behavior.
local function strikes(ctx, summon, attacker, state)
    local simulacrum = ctx:get(summon, "magic.summon_simulacrum")
    local undead = ctx:get(summon, "magic.summon_undead")

    if simulacrum or undead then
        local base_id = simulacrum and simulacrum.base_kind_id or
            undead.base_kind_id
        return catalog.get("monsters", base_id).attacks,
            simulacrum ~= nil
    end

    if attacker.kind_id == monsters.MONS_ANIMATED_ARMOUR then
        local amount = armour.attack_damage(ctx, summon)
        local strike = {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = amount,
        }
        return { strike, strike }, false
    end

    local definition = monster_profile.definition(ctx, summon,
        catalog.get("monsters", attacker.kind_id))

    if state.heads > 0 then
        local repeated = {}

        for _ = 1, state.heads do
            repeated[#repeated + 1] = definition.attacks[1]
        end

        return repeated, false
    end

    return definition.attacks, false
end

-- Example: summon_melee.attack(ctx, summon, target) with actor without Summon component -> false without an attack
-- Called from the ordinary monster-vs-monster combat dispatch. Special
-- derived bodies, hydra heads, and power-scaled HD use source attack dice;
-- other allies stay on the generic monster melee path.
function summon_melee.attack(ctx, summon, target)
    local state = ctx:get(summon, component.SUMMON)

    if not state then
        return false
    end

    local attacker = ctx:get(summon, component.ACTOR)

    local adjusted = ctx:get(summon, component.SUMMON_STATS)
    local blob = ctx:get(summon, component.SLIME_BLOB)
    local special = state.heads > 0 or adjusted ~= nil or
        blob ~= nil or
        ctx:has(summon, "magic.summon_simulacrum") or
        ctx:has(summon, "magic.summon_undead") or
        attacker.kind_id == monsters.MONS_ANIMATED_ARMOUR or
        ctx:has(summon, component.PLAYER_ILLUSION) or
        attacker.kind_id == monsters.MONS_ELDRITCH_TENTACLE

    if not special then
        return false
    end

    local victim = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not victim or not health then
        error("summon melee target lacks actor or health")
    end

    local attacker_def = monster_profile.definition(ctx, summon,
        catalog.get("monsters", attacker.kind_id))
    local victim_def = monster_profile.definition(ctx, target,
        catalog.get("monsters", victim.kind_id))
    local attacks, cold_copy = strikes(ctx, summon, attacker, state)
    local hd = monster_stats.hit_dice(ctx, summon, attacker_def,
        adjusted and adjusted.hd or nil)
    local copied = ctx:has(summon, "magic.summon_simulacrum") or
        ctx:has(summon, "magic.summon_undead")
    local combat = ctx:get(target, "core.combat")

    for _, strike in ipairs(attacks or {}) do
        local current_actor = ctx:get(target, component.ACTOR)

        health = ctx:get(target, component.HEALTH)

        if not current_actor or not health or
            health.current <= 0 then
            break
        end

        -- A preceding Chaos strike may have changed the target's kind.
        -- Rebuild its read profile before resolving the next head.
        victim_def = monster_profile.definition(ctx, target,
            catalog.get("monsters", current_actor.kind_id))

        if strike and strike.type_id ~= "AT_NONE" then
            local base = strike.damage

            if copied then
                base = math.max(1, math.floor(4 * base / 5))
            end

            -- A merged slime strikes with all of its constituent bodies.
            -- The size is saved on the actor, so restore keeps this damage.
            if blob then
                base = base * blob.size
            end

            -- A claw, bite, or other natural strike does not carry the
            -- brand of an item the summon happens to hold.
            local weapon = nil

            if strike.type_id == "AT_HIT" then
                weapon = equipment.monster_melee(ctx, summon)
            end
            local outcome = melee.monster(ctx, {
                attacker = summon,
                hd = hd,
                damage = base,
                type_id = strike.type_id,
                flavour_id = strike.flavour_id,
                weapon = weapon,
            }, {
                ev = defense.evasion(ctx, target, victim_def),
                ac = defense.armour(ctx, target, victim_def),
                gdr = 0,
                shield_class = 0,
                shield_blocks = combat and combat.shield_blocks or 0,
            })

            if combat then
                combat.shield_blocks = outcome.shield_blocks
                ctx:set(target, "core.combat", combat)
            end

            local dealt = outcome.damage

            if cold_copy and outcome.kind == "hit" and
                strike.flavour_id ~= "AF_REACH" and
                strike.flavour_id ~= "AF_CRUSH" and
                strike.flavour_id ~= "AF_TRAMPLE" then
                local cold = hd + ctx:random("spell", math.max(1, hd * 2))
                dealt = dealt + magic_damage.monster_elemental(ctx,
                    target, cold, "MR_RES_COLD")
            end

            if dealt > 0 then
                health, dealt = monster_health.damage(ctx, target, dealt,
                    summon)

                if dealt > 0 and health.current == 0 and
                    targets.allied(ctx, summon) then
                    ctx:signal("player_kill", target)
                end
            end

            local illusion = ctx:get(summon,
                component.PLAYER_ILLUSION)
            local lord = ctx:get(summon, component.PANDEMONIUM_LORD)
            local lord_brand = lord and
                lord.brand_id ~= weapon_brands.NORMAL and lord.brand_id
            local brand_id = weapon and weapon.brand or
                strike.type_id == "AT_HIT" and illusion and
                illusion.brand_id or lord_brand

            if outcome.kind == "hit" and brand_id then
                local hit = {
                    attacker = summon,
                    attacker_name = attacker_def.name,
                    defender = target,
                    definition = victim_def,
                    damage_done = dealt,
                    health = health,
                    weapon_entity = weapon and weapon.entity,
                    player_credit = targets.allied(ctx, summon),
                }

                target_brands.apply(ctx, brand_id, hit)
                health = hit.health

                if hit.banished or hit.moved then
                    break
                end
            end
        end
    end

    local owner = targets.allied(ctx, summon) and "Your " or "The "

    ctx:emit("combat", owner .. attacker_def.name ..
        " attacks the " .. victim_def.name .. ".")
    return true
end

return summon_melee
