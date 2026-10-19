local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local failure = require("policy.magic.failure")
local records = require("policy.character.spell_records")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local trajectory = require("policy.combat.trajectory")
local roll = require("policy.combat.roll")
local spellbook = require("policy.combat.monster_spellbook")
local monster_effects = require("policy.combat.monster_spells")
local streams = require("constants.rng_streams")
local senses = require("policy.character.senses")

local servitor = {}

local ordered = {
    spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    spells.SPELL_IOOD,
    spells.SPELL_IRON_SHOT,
    spells.SPELL_BOLT_OF_COLD,
    spells.SPELL_LIGHTNING_BOLT,
    spells.SPELL_FIREBALL,
    spells.SPELL_STONE_ARROW,
    spells.SPELL_LRD,
    spells.SPELL_AIRSTRIKE,
    spells.SPELL_FORCE_LANCE,
    spells.SPELL_CONJURE_BALL_LIGHTNING,
    spells.SPELL_FREEZING_CLOUD,
    spells.SPELL_MEPHITIC_CLOUD,
    spells.SPELL_STICKY_FLAME,
}

-- Monster servitors inherit every eligible spell in this fixed source
-- priority order. The caster's current book is sampled only at creation.
local function monster_spells(ctx, caster)
    local book = spellbook.for_actor(ctx, caster)
    local known = {}

    for _, slot in ipairs(book and book.slots or {}) do
        known[slot.spell_id] = true
    end

    local selected = {}
    local levels = 0

    for _, id in ipairs(ordered) do
        if known[id] then
            -- The source priority list is broader than the current monster
            -- resolver set. Mod effect files become eligible automatically;
            -- missing effects cannot enter a saved book that AI will cast.
            local available, effect = pcall(monster_effects.effect, id)

            if available and type(effect) == "table" and
                type(effect.plan) == "function" and
                type(effect.resolve) == "function" then
                selected[#selected + 1] = id
                levels = levels + catalog.get("spells", id).level
            end
        end
    end

    return selected, levels
end

-- Source initialization rolls one HD and HP profile, then records every
-- weighted spell slot. The actor's later AI reads only this saved snapshot.
function servitor.spawn_monster(ctx, caster, power)
    local spell_ids, total_levels = monster_spells(ctx, caster)
    local hd = 9 + roll.random_divide(ctx, power,
        14, streams.MONSTER_SPELL)
    local hp = 60

    for _ = 1, 7 do
        hp = hp + 1 + roll.draw(ctx, streams.MONSTER_SPELL, 5)
    end

    local frequencies = {}

    for index, id in ipairs(spell_ids) do
        local level = catalog.get("spells", id).level

        frequencies[index] = math.max(1,
            roll.random_divide(ctx, level * 67,
                total_levels, streams.MONSTER_SPELL))
    end

    local creature = summons.spawn(ctx, caster,
        spells.SPELL_SPELLFORGED_SERVITOR,
        monsters.MONS_SPELLFORGED_SERVITOR, 4, 1, {
            hp = hp,
            hd = hd,
        })

    if creature then
        ctx:add(creature, component.SUMMON_SERVITOR, {
            spell_id = spell_ids[1] or "",
            hd = hd,
            spell_ids = spell_ids,
            frequencies = frequencies,
        })

        if senses.player_sees_actor(ctx, caster) then
            ctx:emit("spell",
                "The caster summons a spellforged servitor!")
        end
    end

    return creature
end

-- Monster-side zap-data.h damage and to-hit, with monster power HD * 12.
local bolts = {
    [spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR] = {
        cap = 200,
        sides_base = 16,
        sides_power_divisor = 10,
        hit_base = 22,
        hit_power_divisor = 20,
    },
    [spells.SPELL_IRON_SHOT] = {
        cap = 200,
        sides_base = 8,
        sides_power_divisor = 9,
        hit_base = 20,
        hit_power_divisor = 25,
    },
    [spells.SPELL_STONE_ARROW] = {
        cap = 50,
        sides_base = 5,
        sides_power_divisor = 10,
        hit_base = 14,
        hit_power_divisor = 35,
    },
}

-- Walk source priority order and skip unknown or high-failure spells before choosing the servitor's bolt.
local function chosen_spell(ctx, player)
    for _, id in ipairs(ordered) do
        local record = records.find(ctx, player, id)

        if record and record.state.known_slot > 0 then
            local spell = catalog.get("spells", id)

            if failure.profile(ctx, player, spell).raw < 50 then
                return id
            end
        end
    end

    return nil
end

-- Bound the spell catalog's maximum range to the servitor's seven-cell targeting reach.
local function range_for(id)
    local spell = catalog.get("spells", id)

    return math.min(7, tonumber(spell.max_range_expr) or 7)
end

-- Trace the shot before rolling hit and damage; another actor intercepting the ray prevents this cast.
local function fire(ctx, entity, target, position, state)
    local destination = ctx:get(target, component.POSITION)
    local reach = range_for(state.spell_id)
    local path = trajectory.trace(ctx, position.level_id,
        position.x, position.y, destination.x, destination.y, reach)
    local contact = path.contacts[1]

    if not contact or contact.actor ~= target then
        return false
    end

    local bolt = bolts[state.spell_id]
    local power = math.min(bolt.cap, state.hd * 12)
    local definition = catalog.get("monsters",
        ctx:get(target, component.ACTOR).kind_id)
    local hit = bolt.hit_base + math.floor(power / bolt.hit_power_divisor)
    local attack = summons.roll(ctx, hit)
    local evasion = summons.roll(ctx, math.max(1,
        defense.evasion(ctx, target, definition)))

    if attack >= evasion then
        local raw = 0
        local sides = bolt.sides_base +
            math.floor(power / bolt.sides_power_divisor)

        for _ = 1, 3 do
            raw = raw + 1 + summons.roll(ctx, sides)
        end

        blast.hit(ctx, target, raw, nil, entity)
    end

    ctx:emit("combat", "Your spellforged servitor casts " ..
        catalog.get("spells", state.spell_id).name .. ".")

    return true
end

-- Fire at a reachable target, otherwise move toward it or follow the owner to regain a firing lane.
function servitor.act(ctx, entity, position)
    local state = ctx:get(entity, component.SUMMON_SERVITOR)
    local target, distance = blast.nearest_hostile(ctx, entity,
        position, 7)

    if target and distance <= range_for(state.spell_id) and
        fire(ctx, entity, target, position, state) then
        return { kind = intent_ids.MONSTER_ABILITY, spell_id = state.spell_id }
    end

    local destination = target and ctx:get(target, component.POSITION) or
        ctx:get(ctx:get(entity, component.SUMMON).owner, component.POSITION)

    if destination and destination.level_id == position.level_id and
        (not distance or distance > 1) then
        local dx, dy, found = ctx:route_step(position.level_id,
            position.x, position.y, destination.x, destination.y,
            target or ctx:player())

        if found and ctx:walkable(position.level_id,
            position.x + dx, position.y + dy) and
            not ctx:actor_at(position.level_id,
                position.x + dx, position.y + dy) then
            return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
        end
    end

    return { kind = intent_ids.MONSTER_WAIT }
end

-- Example: A player with no supported known spell cannot prepare Spellforged Servitor.
-- Source: spl-summoning.cc:player_servitor_spell chooses the first known
-- castable spell in this priority order. Until allied area/projectile spells
-- exist, only the three source physical bolts are accepted at preparation.
function servitor.prepare(ctx, player)
    local id = chosen_spell(ctx, player)

    if not id then
        return "You know no spell your servitor can cast."
    end

    if not bolts[id] then
        return "Your servitor cannot yet cast " ..
            catalog.get("spells", id).name .. "."
    end
end

-- Freeze the chosen spell and rolled HD in ECS state so later turns cast with the summoning result.
function servitor.resolve(ctx, player, _, _, power)
    local id = chosen_spell(ctx, player)
    local quotient = math.floor(power / 14)

    if summons.roll(ctx, 14) < power % 14 then
        quotient = quotient + 1
    end

    local hp = 60

    for _ = 1, 7 do
        hp = hp + 1 + summons.roll(ctx, 5)
    end

    local creature = summons.spawn(ctx, player,
        spells.SPELL_SPELLFORGED_SERVITOR, monsters.MONS_SPELLFORGED_SERVITOR, 4, 1, {
            hp = hp,
        })

    if creature then
        ctx:add(creature, component.SUMMON_SERVITOR, {
            spell_id = id,
            hd = 9 + quotient,
        })
        ctx:emit("spell", "You summon a servant imbued with your destructive magic!")
    end
end

registry.add(spells.SPELL_SPELLFORGED_SERVITOR, {
    prepare = servitor.prepare,
    resolve = servitor.resolve,
})

return servitor
