local component = require("constants.component")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local form_ids = require("constants.form_ids")
local player_health = require("policy.combat.player_health")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")

local sticky = {}

local watery = {
    [terrain.DNGN_SHALLOW_WATER] = true,
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_OPEN_SEA] = true,
    [terrain.DNGN_TOXIC_BOG] = true,
    [terrain.DNGN_MANGROVE] = true,
}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function resistance(definition, wanted)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == wanted then
            return entry.level
        end
    end

    return 0
end

local function duration(ctx, speed, degree)
    -- mon-ench.cc:2275,2379 gives a speed-adjusted, asymmetrically
    -- fuzzed duration for each added degree of ENCH_STICKY_FLAME.
    speed = math.max(1, math.min(100, speed))

    local modified_speed = math.max(1, math.floor(2000 / speed))
    local centiturns = math.max(2,
        math.floor(1000 * degree / modified_speed))
    local speed_duration = roll.random_divide(ctx, 100, speed)
    local raw = centiturns * speed_duration
    local low = math.floor(60 * raw / 100)
    local high = math.floor(40 * raw / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)

    return math.max(15, raw + fuzz - low)
end

function sticky.apply(ctx, source, target, definition, dealt)
    -- beam.cc:napalm_monster excludes insubstantial and sticky-flame immune
    -- monsters; the on-hit damage may be zero and still add one degree.
    if has_flag(definition, "M_INSUBSTANTIAL") or
        resistance(definition, "MR_RES_STICKY_FLAME") > 0 then
        return false
    end

    local levels = 1

    if dealt > 1 then
        levels = math.min(4, 1 + math.floor(
            ctx:random("spell", dealt) / 2))
    end

    local actor = ctx:get(target, component.ACTOR)
    local current = ctx:get(target, component.STICKY_FLAME)
    local previous = current and current.degree or 0
    local added = duration(ctx, actor.speed, levels)

    if current then
        current.degree = math.min(4, current.degree + levels)
        current.remaining_aut = current.remaining_aut + added
        current.max_aut = math.max(current.max_aut, current.remaining_aut)
        current.source = source
        ctx:set(target, component.STICKY_FLAME, current)
    else
        current = {
            degree = math.min(4, levels),
            remaining_aut = added,
            max_aut = added,
            source = source,
        }
        ctx:add(target, component.STICKY_FLAME, current)
    end

    if current.degree > previous then
        ctx:emit("spell", "The " .. definition.name ..
            " is covered in liquid flames!")
    end

    return true
end

function sticky.tick(ctx, target)
    local state = ctx:get(target, component.STICKY_FLAME)
    local health = ctx:get(target, component.HEALTH)

    if not state or not health or health.current <= 0 then
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local position = ctx:get(target, component.POSITION)
    local definition = catalog.get("monsters", actor.kind_id)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    -- terrain.cc:feat_is_watery and mon-ench.cc:1516; flying monsters
    -- remain above the extinguishing water surface.
    if watery[feature] and not has_flag(definition, "M_FLIES") then
        ctx:remove(target, component.STICKY_FLAME)
        ctx:emit("spell", "The flames covering the " ..
            definition.name .. " go out.")
        return
    end

    local raw = 2 + roll.melee(ctx, 4) + roll.melee(ctx, 4)
    local amount = damage.monster_elemental(ctx, target, raw,
        "MR_RES_FIRE")

    if amount > 0 then
        damage.apply(ctx, target, amount, state.source)
        ctx:emit("spell", "The " .. definition.name .. " burns!")
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(target, component.STICKY_FLAME)
        return
    end

    if state.degree > 1 then
        local factor = state.degree * (state.degree + 1) / 2

        if state.remaining_aut < state.max_aut * (factor - 1) / factor then
            state.degree = state.degree - 1
            state.max_aut = state.remaining_aut
        end
    end

    ctx:set(target, component.STICKY_FLAME, state)
end

function sticky.validate(ctx, target)
    local state = ctx:get(target, component.STICKY_FLAME)

    if state and (state.degree < 1 or state.degree > 4 or
        state.remaining_aut < 1 or state.max_aut < state.remaining_aut or
        type(state.source) ~= "number" or state.source <= 0) then
        error("monster " .. ctx:id(target) ..
            " has invalid sticky flame state")
    end
end

local function player_immune(ctx, target)
    if ctx:has(target, component.WATER_HOLD) then
        return true
    end

    local form = ctx:get(target, component.PLAYER_FORM)

    if form and (form.form_id == form_ids.WISP or
        form.form_id == form_ids.STORM) then
        return true
    end

    local position = ctx:get(target, component.POSITION)

    return watery[ctx:cell(position.level_id,
        position.x, position.y)] == true
end

-- player.cc:napalm_player stores a capped duration, separate from the
-- degree-based monster enchantment but in the same saved ECS state.
function sticky.apply_player(ctx, source, target)
    if player_immune(ctx, target) then
        return false
    end

    local amount = 1 + math.floor((ctx:random("monster_spell", 7) +
        ctx:random("monster_spell", 7) +
        ctx:random("monster_spell", 7)) / 3)
    local current = ctx:get(target, component.STICKY_FLAME)
    local remaining = math.min(1000,
        (current and current.remaining_aut or 0) + amount * 10)

    local state = {
        degree = 1,
        remaining_aut = remaining,
        max_aut = remaining,
        source = source,
    }

    if current then
        ctx:set(target, component.STICKY_FLAME, state)
    else
        ctx:add(target, component.STICKY_FLAME, state)
    end
    ctx:emit("combat", "You are covered in liquid flames!")

    return true
end

function sticky.tick_player(ctx, target, aut)
    local state = ctx:get(target, component.STICKY_FLAME)

    if not state then
        return
    end

    local position = ctx:get(target, component.POSITION)

    if watery[ctx:cell(position.level_id, position.x, position.y)] then
        ctx:remove(target, component.STICKY_FLAME)
        ctx:emit("combat", "The flames go out!")
        return
    end

    local raw = 1 + math.floor((ctx:random("monster_spell", 9) +
        ctx:random("monster_spell", 9)) / 2)
    local resisted = damage.player_elemental(ctx, target, raw,
        resistances.FIRE)
    local amount = math.floor(resisted * math.min(aut,
        state.remaining_aut) / 10)

    player_health.damage(ctx, target, amount, false, state.source)
    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(target, component.STICKY_FLAME)
    else
        ctx:set(target, component.STICKY_FLAME, state)
    end
end

function sticky.update(ctx, entity, aut)
    if ctx:has(entity, component.PLAYER) then
        sticky.tick_player(ctx, entity, aut)
    elseif ctx:has(entity, component.AI) then
        sticky.tick(ctx, entity)
    end
end

register.system({
    id = "zap.sticky_flame.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = sticky.update,
})

return sticky
