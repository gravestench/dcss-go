local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local defense = require("policy.combat.monster_defense")
local melee = require("policy.combat.melee")
local magic_damage = require("policy.magic.damage")
local armour = require("policy.magic.effects.summons.animate_armour")

local summon_melee = {}

-- Source: melee-attack.cc:AF_PURE_FIRE and monster::suicide(-10). A vortex
-- has no physical strike; successful contact burns and destroys it.
local function fire_vortex_attack(ctx, summon, target, attacker)
    local victim = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local vortex_health = ctx:get(summon, component.HEALTH)

    if not victim or not health or not vortex_health then
        error("fire vortex contact requires actor and health")
    end

    local attacker_def = catalog.get("monsters", attacker.kind_id)
    local victim_def = catalog.get("monsters", victim.kind_id)
    local combat = ctx:get(target, "core.combat")
    local outcome = melee.monster(ctx, {
        hd = attacker_def.hd,
        damage = 0,
        type_id = "AT_HIT",
        flavour_id = "AF_PURE_FIRE",
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

    if outcome.kind == "hit" then
        local raw = math.floor(attacker_def.hd * 3 / 2) +
            ctx:random("spell", attacker_def.hd)
        local ac = defense.armour(ctx, target, victim_def)
        local after_ac = math.max(0, raw -
            math.floor(ctx:random("spell", ac + 1) / 2))
        local amount = magic_damage.monster_elemental(ctx, target,
            after_ac, "MR_RES_FIRE")

        magic_damage.apply(ctx, target, amount)
        vortex_health.current = 0
        ctx:set(summon, component.HEALTH, vortex_health)
        ctx:emit("combat", "Your fire vortex burns the " ..
            victim_def.name .. ".")
    end

    return true
end

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

    local definition = catalog.get("monsters", attacker.kind_id)

    if state.heads > 0 then
        local repeated = {}

        for _ = 1, state.heads do
            repeated[#repeated + 1] = definition.attacks[1]
        end

        return repeated, false
    end

    return definition.attacks, false
end

-- Called from the ordinary monster-vs-monster combat dispatch. Special
-- derived bodies, hydra heads, and power-scaled HD use source attack dice;
-- other allies stay on the generic monster melee path.
function summon_melee.attack(ctx, summon, target)
    local state = ctx:get(summon, component.SUMMON)

    if not state then
        return false
    end

    local attacker = ctx:get(summon, component.ACTOR)

    if attacker.kind_id == monsters.MONS_FIRE_VORTEX then
        return fire_vortex_attack(ctx, summon, target, attacker)
    end

    local adjusted = ctx:get(summon, component.SUMMON_STATS)
    local special = state.heads > 0 or adjusted ~= nil or
        ctx:has(summon, "magic.summon_simulacrum") or
        ctx:has(summon, "magic.summon_undead") or
        attacker.kind_id == monsters.MONS_ANIMATED_ARMOUR or
        attacker.kind_id == monsters.MONS_ELDRITCH_TENTACLE

    if not special then
        return false
    end

    local victim = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not victim or not health then
        error("summon melee target lacks actor or health")
    end

    local attacker_def = catalog.get("monsters", attacker.kind_id)
    local victim_def = catalog.get("monsters", victim.kind_id)
    local attacks, cold_copy = strikes(ctx, summon, attacker, state)
    local hd = adjusted and adjusted.hd or attacker_def.hd
    local copied = ctx:has(summon, "magic.summon_simulacrum") or
        ctx:has(summon, "magic.summon_undead")
    local combat = ctx:get(target, "core.combat")

    for _, strike in ipairs(attacks or {}) do
        if health.current <= 0 then
            break
        end

        if strike and strike.type_id ~= "AT_NONE" then
            local base = strike.damage

            if copied then
                base = math.max(1, math.floor(4 * base / 5))
            end

            local outcome = melee.monster(ctx, {
                hd = hd,
                damage = base,
                type_id = strike.type_id,
                flavour_id = strike.flavour_id,
                weapon = equipment.monster_melee(ctx, summon),
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
                dealt = dealt + magic_damage.elemental(cold,
                    victim_def, "MR_RES_COLD")
            end

            if dealt > 0 then
                local alive = health.current > 0
                health.current = math.max(0, health.current - dealt)
                ctx:set(target, component.HEALTH, health)

                if alive and health.current == 0 then
                    ctx:signal("player_kill", target)
                end
            end
        end
    end

    ctx:emit("combat", "Your " .. attacker_def.name ..
        " attacks the " .. victim_def.name .. ".")
    return true
end

return summon_melee
