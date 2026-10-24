-- Holy, Pure Fire, and Sear are source monster contact effects rather than
-- weapon brands. They share the normal landed-hit envelope but differ in
-- whether physical HP loss is required and what saved state they change.
local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local holy_wrath = require("policy.combat.monster_target_brands.holy_wrath")
local holiness = require("policy.character.holiness")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local elemental = {}

-- Source holy energy vulnerability is a live property of the victim. The
-- monster brand already knows its exceptional profane-servitor immunity.
local function holy_susceptible(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return holiness.undead_or_demonic(ctx, hit.defender)
    end

    local definition = hit.defender_definition

    if not definition then
        local actor = ctx:get(hit.defender, component.ACTOR)

        definition = actor and catalog.get("monsters", actor.kind_id)
    end

    return definition and holy_wrath.susceptible(definition) or false
end

-- All bonus packets use the ordinary actor health owner. Allied secondary
-- kills emit the same player-kill signal as their physical strike.
local function apply_damage(ctx, hit, amount)
    if amount <= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        local _, dealt = player_health.damage(ctx, hit.defender,
            amount, false, hit.attacker)

        return dealt > 0
    end

    local health, dealt = monster_health.damage(ctx, hit.defender,
        amount, hit.attacker)

    if hit.player_credit and dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", hit.defender)
    end

    return dealt > 0
end

-- Source AF_HOLY uses the attack's defined damage, not the post-armour HP
-- loss. The ordinary melee gate has already required positive physical
-- damage before this owner is called.
function elemental.holy(ctx, hit)
    if hit.physical_damage <= 0 or not holy_susceptible(ctx, hit) then
        return false
    end

    local amount = math.floor((hit.attack_base_damage or 0) * 3 / 4)

    return apply_damage(ctx, hit, amount)
end

-- The source's half-AC rule first rolls against full AC and halves only the
-- saved value. Fire resistance then sees the remaining packet. Fire vortices
-- spend themselves on landed contact even if resistance prevents HP loss.
function elemental.pure_fire(ctx, hit)
    local hd = math.max(0, hit.hit_dice or 0)
    local raw = math.floor(hd * 3 / 2) + roll.melee(ctx, hd)
    local saved = math.floor(roll.melee(ctx,
        math.max(0, hit.defender_ac or 0) + 1) / 2)
    local after_ac = math.max(0, raw - saved)
    local amount

    if ctx:has(hit.defender, component.PLAYER) then
        amount = damage.player_elemental(ctx, hit.defender,
            after_ac, resistances.FIRE)
    else
        amount = damage.monster_elemental(ctx, hit.defender,
            after_ac, resistances.FIRE)
    end

    local attacker = ctx:get(hit.attacker, component.ACTOR)

    if attacker and attacker.kind_id == monsters.MONS_FIRE_VORTEX then
        local health = ctx:get(hit.attacker, component.HEALTH)

        if health then
            health.current = 0
            ctx:set(hit.attacker, component.HEALTH, health)
        end
    end

    return apply_damage(ctx, hit, amount)
end

-- Sear's one-in-three proc feeds the existing saved vulnerability state.
-- Players use the source fifty-turn cap; monster enchants add their time.
function elemental.sear(ctx, hit)
    if hit.physical_damage <= 0 or roll.melee(ctx, 3) ~= 0 then
        return false
    end

    local duration = (3 + roll.melee(ctx,
        math.max(0, hit.attack_base_damage or 0))) * 10
    local state = ctx:get(hit.defender,
        component.FIRE_VULNERABILITY)
    local remaining = (state and state.remaining_aut or 0) + duration

    if ctx:has(hit.defender, component.PLAYER) then
        remaining = math.min(500, remaining)
    end

    if state then
        state.remaining_aut = remaining
        ctx:set(hit.defender, component.FIRE_VULNERABILITY, state)
    else
        ctx:add(hit.defender, component.FIRE_VULNERABILITY, {
            remaining_aut = remaining,
        })
    end

    return true
end

return elemental
