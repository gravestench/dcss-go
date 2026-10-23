-- Theory of operation: Uskayaw accumulates actual foe damage in one saved
-- player component. A reaction system converts the whole turn's pooled
-- damage into piety, then clears the pool. Quiet turns slowly drain piety
-- toward the first star after a short grace period.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local gods = require("constants.gods")
local kinds = require("constants.religion_conduct")
local piety = require("policy.religion.piety")

local uskayaw = {}

-- The source's mons_threat_level compares XP with the player's current
-- level threshold. The four bands change the damage percentage weight.
local function threat(ctx, player, experience)
    local progress = ctx:get(player, component.PROGRESSION)
    local identity = ctx:get(player, component.PLAYER)

    if not progress or not identity then
        error("Uskayaw damage requires player level and species")
    end

    local species = catalog.get(categories.SPECIES, identity.species_id)
    local needed = formulas.experience_needed(progress.level, species.xp)
    local tension = math.floor(experience /
        (1 + math.sqrt(needed / 30)))

    if tension <= 0 then
        return 0
    elseif tension <= 5 then
        return 1
    elseif tension <= 32 then
        return 2
    end

    return 3
end

-- Source stepdown_value(5, 10, 20, 40) softens large bursts before the
-- minimum of one point per hurt monster is applied.
local function stepped(value)
    if value < 10 then
        return value
    end

    local reduced = 5 + math.floor(5 *
        math.log(1 + (value - 5) / 5) / math.log(2))

    return math.min(40, reduced)
end

-- This response deliberately returns false from before: individual hits
-- must never take the generic immediate like-response piety path.
local function collect(ctx, player, event)
    if event.id ~= kinds.HURT_FOE then
        return true
    end

    if type(event.damage) ~= "number" or event.damage <= 0 or
        type(event.max_health) ~= "number" or event.max_health <= 0 or
        type(event.experience) ~= "number" or event.experience < 0 then
        error("Uskayaw hurt conduct requires positive live damage facts")
    end

    local band = threat(ctx, player, event.experience)
    local weight = ((band + 1) * 2) ^ 2
    local value = ctx:random("religion", 3) +
        math.floor(weight * event.damage / event.max_health)
    local state = ctx:get(player, component.RELIGION_USKAYAW_MOMENTUM) or {
        num_hurt = 0,
        hurt_value = 0,
        aut_since_gain = 0,
    }

    state.num_hurt = state.num_hurt + 1
    state.hurt_value = state.hurt_value + value

    if ctx:has(player, component.RELIGION_USKAYAW_MOMENTUM) then
        ctx:set(player, component.RELIGION_USKAYAW_MOMENTUM, state)
    else
        ctx:add(player, component.RELIGION_USKAYAW_MOMENTUM, state)
    end

    return false
end

-- Source div_rand_round only consumes a religion draw for a remainder.
-- Decay never crosses the first piety breakpoint.
local function decay(ctx, player, state, worship, elapsed_aut)
    if worship.piety <= piety.breakpoint(1) then
        return
    end

    state.aut_since_gain = state.aut_since_gain + elapsed_aut

    if state.aut_since_gain <= 30 then
        return
    end

    local loss = math.floor(state.aut_since_gain / 10)
    local remainder = state.aut_since_gain % 10

    if remainder > 0 and ctx:random("religion", 10) < remainder then
        loss = loss + 1
    end

    loss = math.min(loss, worship.piety - piety.breakpoint(1))
    piety.lose(ctx, player, loss)
end

-- Resolve once per player action after all damage systems. A saved pool is
-- reset even if upper piety taper refuses the offered points.
function uskayaw.tick(ctx, player, elapsed_aut)
    if elapsed_aut < 0 then
        error("Uskayaw reaction requires nonnegative elapsed time")
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local state = ctx:get(player, component.RELIGION_USKAYAW_MOMENTUM)

    if not worship or worship.god_id ~= gods.USKAYAW then
        if state then
            ctx:remove(player, component.RELIGION_USKAYAW_MOMENTUM)
        end

        return
    end

    state = state or {
        num_hurt = 0,
        hurt_value = 0,
        aut_since_gain = 0,
    }

    if state.num_hurt > 0 then
        local gain = math.max(state.num_hurt, stepped(state.hurt_value))

        piety.gain(ctx, player, gain, 1, true)
        state.aut_since_gain = 0
    else
        decay(ctx, player, state, worship, elapsed_aut)
    end

    state.num_hurt = 0
    state.hurt_value = 0

    if ctx:has(player, component.RELIGION_USKAYAW_MOMENTUM) then
        ctx:set(player, component.RELIGION_USKAYAW_MOMENTUM, state)
    else
        ctx:add(player, component.RELIGION_USKAYAW_MOMENTUM, state)
    end
end

uskayaw.before = collect
uskayaw.likes = {
    [kinds.HURT_FOE] = {
        description = "you hurt your foes; damage over time does not interest Uskayaw",
        bonus = 0,
        denom_bonus = 1,
        xl_denom = 0,
    },
}

return uskayaw
