local roll = require("policy.combat.roll")
local slow = require("policy.combat.monster_slow")
local component = require("constants.component")
local catalog = require("policy.catalog")
local monster_flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local resistance_ids = require("constants.resistance_ids")
local monster_stats = require("policy.combat.monster_stats")

local enchant = {}

-- spl-goditem.h: dispellable_enchantments. Only currently modeled effects
-- appear here. Summons are valid Unravelling targets without being a buff.
local whole_effects = {
    component.MONSTER_ENFEEBLE,
    component.MONSTER_INFESTATION,
    component.MONSTER_MASS_ENCHANT,
    component.STICKY_FLAME,
    component.INNER_FLAME,
    component.FIRE_VULNERABILITY,
    component.TELEPORT,
    component.PARALYSIS,
}

local function active_fields(state, fields)
    if not state then
        return false
    end

    for _, field in ipairs(fields) do
        if state[field] and state[field] > 0 then
            return true
        end
    end

    return false
end

local function naturally_confused(definition)
    if not definition then
        return false
    end

    for _, flag_id in ipairs(definition.flags or {}) do
        if flag_id == "M_CONFUSED" then
            return true
        end
    end

    return false
end

local function definition_for(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        return nil
    end

    return catalog.get("monsters", actor.kind_id)
end

local function partial_effects(ctx, monster)
    if active_fields(ctx:get(monster, component.MONSTER_ENCHANT), {
        "blind_aut", "corrosion_aut", "invisible_aut",
    }) then
        return true
    end

    if active_fields(ctx:get(monster, component.MONSTER_ALLEGIANCE), {
        "charm_aut", "frenzy_aut",
    }) then
        return true
    end

    if active_fields(ctx:get(monster, component.MONSTER_STASIS), {
        "petrifying_aut", "petrified_aut",
    }) then
        return true
    end

    local confusion = ctx:get(monster, component.MONSTER_CONFUSION)

    return confusion ~= nil and confusion.remaining_aut > 0 and
        not naturally_confused(definition_for(ctx, monster))
end

function enchant.can_dispel(ctx, monster)
    if ctx:has(monster, component.SUMMON) or
        ctx:has(monster, component.PROJECTILE_SLOW) or
        partial_effects(ctx, monster) then
        return true
    end

    for _, id in ipairs(whole_effects) do
        if ctx:has(monster, id) then
            return true
        end
    end

    return false
end

local function state(ctx, monster)
    return ctx:get(monster, "magic.monster_enchant") or {
        blind_aut = 0,
        corrosion_aut = 0,
        invisible_aut = 0,
    }
end

local function save(ctx, monster, value)
    if ctx:has(monster, "magic.monster_enchant") then
        ctx:set(monster, "magic.monster_enchant", value)
    else
        ctx:add(monster, "magic.monster_enchant", value)
    end
end

local function resistance(definition, id)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == id then
            return entry.level
        end
    end

    return 0
end

local function flag(definition, id)
    for _, value in ipairs(definition.flags or {}) do
        if value == id then
            return true
        end
    end

    return false
end

function enchant.blinded(ctx, monster)
    local value = ctx:get(monster, "magic.monster_enchant")

    return value ~= nil and (value.blind_aut or 0) > 0
end

function enchant.corroded(ctx, monster)
    local value = ctx:get(monster, "magic.monster_enchant")

    return value ~= nil and (value.corrosion_aut or 0) > 0
end

-- beam.cc:4629-4636 adds ENCH_BLIND once with a HD-scaled duration.
function enchant.blind(ctx, monster, definition)
    if flag(definition, "M_UNBLINDABLE") then
        return false
    end

    local value = state(ctx, monster)

    if value.blind_aut > 0 then
        return false
    end

    local base = math.max(1, roll.random_divide(ctx, 54,
        monster_stats.hit_dice(ctx, monster, definition))) * 10
    value.blind_aut = base + roll.melee(ctx, base + 1)
    save(ctx, monster, value)
    ctx:emit("spell", "The " .. definition.name .. " is blinded.")

    return true
end

-- mon-ench.cc gives corrosion the same duration class as slow.
local function apply_corrosion(ctx, monster, definition, source)
    local actor = ctx:get(monster, "core.actor")
    local modified_speed = math.max(1,
        math.floor((monster_stats.hit_dice(ctx, monster, definition) + 10) *
            10 / math.max(1, actor.speed)))
    local centiturns = math.max(2,
        math.floor(250 / (1 + modified_speed)))
    local speed_duration = roll.random_divide(ctx, 100, actor.speed)
    local raw = centiturns * speed_duration
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)
    local value = state(ctx, monster)
    local was_corroded = value.corrosion_aut > 0

    value.corrosion_aut = value.corrosion_aut +
        math.max(15, raw + fuzz - low)
    save(ctx, monster, value)

    if not was_corroded then
        ctx:emit("spell", source or
            ("The " .. definition.name .. " corrodes!"))
    end

    return true
end

-- monster.cc:acid_corrode gives a 2/3 application chance below rAcid 3.
function enchant.corrode(ctx, monster, definition)
    if resistance(definition, resistance_ids.ACID) >= 3 or
        roll.melee(ctx, 3) == 0 then
        return false
    end

    return apply_corrosion(ctx, monster, definition)
end

-- monster.cc:corrode_equipment gives rCorr a 50% protection chance.
function enchant.corrode_equipment(ctx, monster, definition, source)
    if flag(definition, monster_flags.AVATAR) or
        definition.id == monsters.MONS_PLAYER_SHADOW then
        return false
    end

    if resistance(definition, resistance_ids.ACID) > 0 and
        roll.melee(ctx, 2) == 0 then
        return false
    end

    return apply_corrosion(ctx, monster, definition,
        source .. " corrodes the " .. definition.name .. "!")
end

-- spl-goditem.cc:debuff_monster removes dispellable enchantments. Known
-- spell effects contribute their own saved ECS conditions here.
function enchant.dispel(ctx, monster, definition)
    local changed = slow.remove(ctx, monster)
    local value = ctx:get(monster, component.MONSTER_ENCHANT)

    if value and ((value.blind_aut or 0) > 0 or
        (value.corrosion_aut or 0) > 0 or
        (value.invisible_aut or 0) > 0) then
        ctx:remove(monster, component.MONSTER_ENCHANT)
        changed = true
    end

    local allegiance = ctx:get(monster, component.MONSTER_ALLEGIANCE)

    if allegiance and (allegiance.charm_aut > 0 or
        allegiance.frenzy_aut > 0) then
        allegiance.charm_aut = 0
        allegiance.frenzy_aut = 0

        if allegiance.fatigue_aut > 0 then
            ctx:set(monster, component.MONSTER_ALLEGIANCE, allegiance)
        else
            ctx:remove(monster, component.MONSTER_ALLEGIANCE)
        end

        changed = true
    end

    local stasis = ctx:get(monster, component.MONSTER_STASIS)

    if stasis and (stasis.petrifying_aut > 0 or
        stasis.petrified_aut > 0) then
        stasis.petrifying_aut = 0
        stasis.petrified_aut = 0

        if stasis.hibernating or stasis.sleep_wary_aut > 0 then
            ctx:set(monster, component.MONSTER_STASIS, stasis)
        else
            ctx:remove(monster, component.MONSTER_STASIS)
        end

        changed = true
    end

    if ctx:has(monster, component.MONSTER_CONFUSION) and
        not naturally_confused(definition) then
        ctx:remove(monster, component.MONSTER_CONFUSION)
        changed = true
    end

    for _, id in ipairs(whole_effects) do
        if ctx:has(monster, id) then
            ctx:remove(monster, id)
            changed = true
        end
    end

    if changed then
        ctx:emit("spell", "The " .. definition.name ..
            "'s magical effects unravel!")
    end

    return changed
end

function enchant.tick(ctx, monster)
    local value = ctx:get(monster, "magic.monster_enchant")

    if not value then
        return
    end

    local actor = ctx:get(monster, "core.actor")
    local changed = false

    value.blind_aut = value.blind_aut or 0
    value.corrosion_aut = value.corrosion_aut or 0
    value.invisible_aut = value.invisible_aut or 0

    if value.blind_aut > 0 then
        value.blind_aut = math.max(0, value.blind_aut - 10)
        changed = true

        if value.blind_aut == 0 then
            ctx:emit("duration", "The " .. actor.kind_id ..
                " is no longer blind.")
        end
    end

    if value.corrosion_aut > 0 then
        value.corrosion_aut = math.max(0, value.corrosion_aut - 10)
        changed = true

        if value.corrosion_aut == 0 then
            ctx:emit("duration", "The " .. actor.kind_id ..
                " is no longer covered in acid.")
        end
    end

    if value.invisible_aut > 0 then
        value.invisible_aut = math.max(0, value.invisible_aut - 10)
        changed = true

        if value.invisible_aut == 0 then
            ctx:emit("duration", "The " .. actor.kind_id ..
                " becomes visible again.")
        end
    end

    if changed then
        if value.blind_aut == 0 and value.corrosion_aut == 0 and
            value.invisible_aut == 0 then
            ctx:remove(monster, "magic.monster_enchant")
        else
            ctx:set(monster, "magic.monster_enchant", value)
        end
    end
end

return enchant
