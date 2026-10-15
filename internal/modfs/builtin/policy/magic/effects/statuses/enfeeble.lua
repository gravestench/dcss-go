-- Source: spl-monench.cc:enfeeble_monster, beam.cc:BEAM_ENFEEBLE,
-- melee-attack.cc:apply_damage_modifiers, mon-cast.cc and mon-act.cc.
local component = require("constants.component")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local enfeeble = {}
local books = {}

for _, book in ipairs(catalog.all("monster_spellbooks")) do
    books[book.id] = book
end

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function spell_sensitive(definition)
    local book = books[definition.spellbook_id]

    for _, slot in ipairs(book and book.slots or {}) do
        if has(slot.flags, "MON_SPELL_MAGICAL") or
            has(slot.flags, "MON_SPELL_WIZARD") then
            return true
        end
    end

    return false
end

local function has_attacks(definition)
    local attack = definition.attacks and definition.attacks[1]

    return attack ~= nil and attack.type_id ~= "AT_NONE" and
        attack.damage > 0
end

local function divide_randomly(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

local function duration(ctx, power)
    local extra = divide_randomly(ctx, power, 40)

    if extra <= 0 then
        return 50
    end

    local rolled = ctx:random("spell", extra) +
        ctx:random("spell", extra + 1) +
        ctx:random("spell", extra + 1)

    return (5 + math.floor(rolled / 3)) * 10
end

local function apply(ctx, target, definition, power)
    local weak = has_attacks(definition)
    local antimagic = spell_sensitive(definition)
    local resisted = will.resists(ctx, definition, power)
    local blind = not resisted and not has(definition.flags, "M_UNBLINDABLE")
    local dazed = not resisted

    if not weak and not antimagic and not blind and not dazed then
        ctx:emit("spell", "The " .. definition.name .. " resists.")
        return
    end

    local lasting = duration(ctx, power)
    local current = ctx:get(target, component.MONSTER_ENFEEBLE)
    local next_state = current or {
        weak_aut = 0,
        antimagic_aut = 0,
        blind_aut = 0,
        dazed_aut = 0,
    }

    if weak then
        next_state.weak_aut = math.max(next_state.weak_aut, lasting)
    end

    if antimagic then
        next_state.antimagic_aut = math.max(next_state.antimagic_aut, lasting)
    end

    if blind then
        next_state.blind_aut = math.max(next_state.blind_aut, lasting)
    end

    if dazed then
        next_state.dazed_aut = math.max(next_state.dazed_aut, lasting)
    end

    if current then
        ctx:set(target, component.MONSTER_ENFEEBLE, next_state)
    else
        ctx:add(target, component.MONSTER_ENFEEBLE, next_state)
    end

    if resisted then
        ctx:emit("spell", "The " .. definition.name .. " partially resists.")
    end

    ctx:emit("spell", "The " .. definition.name .. " is enfeebled!")
end

function enfeeble.can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

function enfeeble.cast(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "The enfeebling magic dissipates.")
        return
    end

    local actor = ctx:get(contact.actor, component.ACTOR)
    local health = ctx:get(contact.actor, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    apply(ctx, contact.actor, catalog.get("monsters", actor.kind_id), power)
end

function enfeeble.blinded(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    return current ~= nil and current.blind_aut > 0
end

function enfeeble.dazed(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current or current.dazed_aut <= 0 or
        ctx:random("melee", 4) ~= 0 then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("monster", "The " .. definition.name .. " is lost in a daze.")

    return true
end

function enfeeble.melee_damage(ctx, monster, damage)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if current and current.weak_aut > 0 then
        return math.floor(damage * 2 / 3)
    end

    return damage
end

function enfeeble.antimagic(ctx, monster, slot_flags)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current or current.antimagic_aut <= 0 or
        not (has(slot_flags, "MON_SPELL_MAGICAL") or
            has(slot_flags, "MON_SPELL_WIZARD")) or
        ctx:random("monster_spell", 40 + current.antimagic_aut) < 40 then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("monster", "The " .. definition.name .. " falters for a moment.")

    return true
end

function enfeeble.tick(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current then
        return
    end

    local active = false

    for _, field in ipairs({
        "weak_aut", "antimagic_aut", "blind_aut", "dazed_aut",
    }) do
        current[field] = math.max(0, current[field] - 10)
        active = active or current[field] > 0
    end

    if active then
        ctx:set(monster, component.MONSTER_ENFEEBLE, current)
    else
        ctx:remove(monster, component.MONSTER_ENFEEBLE)
    end
end

return enfeeble
