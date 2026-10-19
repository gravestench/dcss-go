-- Theory of operation: the first snaplasher contact starts a saved grip;
-- its second contact deals the profile's ordinary hit damage. The victim
-- owns escape progress, while the vine head remains the source of the hold.
-- A grip breaks if either actor dies or the head loses adjacency.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local constriction = require("policy.combat.constriction")
local direct = require("policy.combat.monster_direct")
local fighter = require("policy.combat.fighter")
local melee = require("policy.combat.melee")
local monster_defense = require("policy.combat.monster_defense")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")

local grip = {}

-- Vine constriction is physical and adjacent, unlike root magic. A
-- spiny, insubstantial, or jelly body cannot be safely wrapped.
local function eligible(ctx, victim)
    if ctx:has(victim, component.MONSTER_VINE_GRIP) or
        ctx:has(victim, component.CONSTRICTION) then
        return false
    end

    if victim == ctx:player() then
        return true
    end

    local actor = ctx:get(victim, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if definition.genus_id == monsters.MONS_JELLY then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == "M_INSUBSTANTIAL" or flag == "M_SPINY" then
            return false
        end
    end

    return true
end

-- The source can only keep a victim next to the living head, including
-- diagonal cells. This same check governs ticking and save validation.
function grip.adjacent(ctx, source, victim)
    local a = ctx:get(source, component.POSITION)
    local b = ctx:get(victim, component.POSITION)

    return a and b and a.level_id == b.level_id and
        math.max(math.abs(a.x - b.x),
            math.abs(a.y - b.y)) == 1
end

-- Roll a contact with the defender's real shield, evasion, and armour.
-- The shared melee policy leaves AT_CONSTRICT damage at zero on contact.
local function attack(ctx, vine, victim, strike, definition)
    local defense

    if victim == ctx:player() then
        defense = fighter.defense(ctx)
    else
        local actor = ctx:get(victim, component.ACTOR)
        local target = catalog.get(categories.MONSTERS, actor.kind_id)
        local combat = ctx:get(victim, component.COMBAT)

        defense = {
            ev = monster_defense.evasion(ctx, victim, target),
            ac = monster_defense.armour(ctx, victim, target),
            gdr = 0,
            shield_class = 0,
            shield_blocks = combat and combat.shield_blocks or 0,
        }
    end

    local result = melee.monster(ctx, {
        attacker = vine,
        hd = monster_stats.hit_dice(ctx, vine, definition),
        damage = strike.damage,
        type_id = strike.type_id,
        flavour_id = strike.flavour_id,
    }, defense)

    if victim == ctx:player() then
        local combat = ctx:get(victim, component.COMBAT)

        if combat then
            combat.shield_blocks = result.shield_blocks
            ctx:set(victim, component.COMBAT, combat)
        end
    end

    return result
end

-- A vine uses both source attack slots in order: first a zero-damage
-- constriction attempt, then its ordinary lash if both actors survive.
function grip.contact(ctx, vine, victim)
    local actor = ctx:get(vine, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hold = attack(ctx, vine, victim,
        definition.attacks[1], definition)

    if hold.kind == "hit" and eligible(ctx, victim) and
        grip.adjacent(ctx, vine, victim) then
        ctx:add(victim, component.MONSTER_VINE_GRIP, {
            by = vine,
            escape_attempts = 0,
            held_aut = 0,
        })
        ctx:emit("combat", "The vine wraps around its foe!")
    end

    local vine_health = ctx:get(vine, component.HEALTH)
    local victim_health = ctx:get(victim, component.HEALTH)

    if not vine_health or vine_health.current <= 0 or
        not victim_health or victim_health.current <= 0 then
        return
    end

    local lash = attack(ctx, vine, victim,
        definition.attacks[2], definition)

    if lash.kind == "hit" then
        direct.damage(ctx, vine, victim, lash.damage)
        ctx:emit("combat", "The vine lashes its foe!")
    end
end

-- Every attempted move contests the saved grip. Failed attempts spend
-- the turn; success weakens the head's energy before movement continues.
function grip.escape(ctx, victim)
    local state = ctx:get(victim, component.MONSTER_VINE_GRIP)

    if not state then
        return true
    end

    local source_health = ctx:get(state.by, component.HEALTH)

    if not source_health or source_health.current <= 0 or
        not grip.adjacent(ctx, state.by, victim) then
        ctx:remove(victim, component.MONSTER_VINE_GRIP)

        return true
    end

    local actor = ctx:get(state.by, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local attempts = state.escape_attempts + 1

    if not constriction.escape(ctx, attempts, definition.hd) then
        state.escape_attempts = attempts
        ctx:set(victim, component.MONSTER_VINE_GRIP, state)
        ctx:emit("combat", "The vine holds its foe fast.")

        return false
    end

    ctx:remove(victim, component.MONSTER_VINE_GRIP)

    local energy = ctx:get(state.by, component.MONSTER_ENERGY)

    if energy then
        energy.points = math.max(0, energy.points - 5)
        ctx:set(state.by, component.MONSTER_ENERGY, energy)
    end

    ctx:emit("combat", "The vine's foe breaks free.")

    return true
end

-- Damage from this source's zero-base constriction remains zero; the
-- danger is a pulled victim and the vine's separate damaging lash.
function grip.tick(ctx, active, aut)
    for _, victim in ipairs(ctx:query({ component.MONSTER_VINE_GRIP })) do
        local state = ctx:get(victim, component.MONSTER_VINE_GRIP)
        local source_health = ctx:get(state.by, component.HEALTH)
        local victim_health = ctx:get(victim, component.HEALTH)

        if not source_health or source_health.current <= 0 or
            not victim_health or victim_health.current <= 0 or
            not grip.adjacent(ctx, state.by, victim) then
            ctx:remove(victim, component.MONSTER_VINE_GRIP)
        elseif active == state.by then
            state.held_aut = state.held_aut + aut
            ctx:set(victim, component.MONSTER_VINE_GRIP, state)
        end
    end
end

return grip
