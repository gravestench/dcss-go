local component = require("constants.component")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local abilities = require("ids.abilities")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")

local vampire = {}
local RITUAL_AUT = 50
local AUT_PER_RITUAL_TURN = 10

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

function vampire.start(ctx, player)
    if levels.base(ctx, player, mutations.MUT_VAMPIRISM) == 0 then
        return
    end

    if ctx:has(player, component.VAMPIRE) then
        error("vampire state already exists")
    end

    ctx:add(player, component.VAMPIRE, {
        alive = true,
        ritual_kind = "",
        ritual_remaining_aut = 0,
    })
end

function vampire.changed(ctx, player)
    local has_mutation = levels.base(ctx, player,
        mutations.MUT_VAMPIRISM) > 0
    local state = ctx:get(player, component.VAMPIRE)

    if has_mutation and not state then
        vampire.start(ctx, player)
    elseif not has_mutation and state then
        local form = ctx:get(player, component.PLAYER_FORM)

        if form and form.form_id == "bat" then
            require("policy.magic.effects.forms.player").finish(ctx, player)
        end

        ctx:remove(player, component.VAMPIRE)
    end

    if ctx:get(player, component.HEALTH) then
        local forms = require("policy.magic.effects.forms.player")

        forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
    end
end

function vampire.alive(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)

    return not state or state.alive
end

function vampire.bloodless(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)

    return state ~= nil and not state.alive
end

-- Source: melee-attack.cc:_player_vampire_draws_blood. The bite and a good
-- stab share this rule, so each contact path supplies only its trigger.
function vampire.draw_blood(ctx, player, target, definition, damage)
    if not vampire.bloodless(ctx, player) or damage <= 0 or
        ctx:has(target, component.SUMMON) then
        return false
    end

    local has_blood = contains(definition.flags, flags.COLD_BLOOD) or
        contains(definition.flags, flags.WARM_BLOOD)
    local susceptible = contains(definition.holiness, holiness.NATURAL) or
        contains(definition.holiness, holiness.PLANT)
    local firewood = contains(definition.flags, flags.STATIONARY) and
        contains(definition.flags, flags.NO_THREAT)

    if not has_blood or not susceptible or firewood then
        return false
    end

    local player_health = ctx:get(player, component.HEALTH)

    if not player_health then
        error("blood draw requires player health")
    end

    ctx:emit("combat", "You draw the " .. definition.name .. "'s blood!")

    if player_health.current >= player_health.max then
        return true
    end

    local health_policy = require("policy.combat.player_health")

    if not health_policy.can_heal(ctx, player) then
        return true
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local healing = math.min(progress.level,
        2 + ctx:random("combat", damage) + ctx:random("combat", damage))

    if healing > 0 then
        player_health.current = math.min(player_health.max,
            player_health.current + healing)
        ctx:set(player, component.HEALTH, player_health)
        ctx:emit("combat", "You feel better.")
    end

    return true
end

function vampire.begin(ctx, player, ability_id)
    local state = ctx:get(player, component.VAMPIRE)

    if not state or state.ritual_remaining_aut > 0 then
        error("Vampire cannot begin a blood ritual")
    end

    if ability_id == abilities.EXSANGUINATE and state.alive then
        ctx:emit("mutation", "You begin bloodletting.")
    elseif ability_id == abilities.REVIVIFY and not state.alive then
        ctx:emit("mutation", "You begin the revivification ritual.")
    else
        error("Vampire blood ritual does not match state")
    end

    state.ritual_kind = ability_id
    state.ritual_remaining_aut = RITUAL_AUT
    ctx:set(player, component.VAMPIRE, state)
end

function vampire.interrupt(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)

    if not state or state.ritual_remaining_aut == 0 then
        return "You are not performing a blood ritual."
    end

    local message = state.ritual_kind == abilities.EXSANGUINATE and
        "You stop emptying yourself of blood." or
        "You stop your revivification ritual."

    state.ritual_kind = ""
    state.ritual_remaining_aut = 0
    ctx:set(player, component.VAMPIRE, state)

    return message
end

function vampire.advance(ctx, player, aut)
    local state = ctx:get(player, component.VAMPIRE)

    if not state or state.ritual_remaining_aut == 0 or aut <= 0 then
        return
    end

    -- delay.cc decrements duration once per action. Store that countdown in
    -- nominal aut so action-speed changes do not alter the five-step ritual.
    state.ritual_remaining_aut = math.max(0,
        state.ritual_remaining_aut - AUT_PER_RITUAL_TURN)

    if state.ritual_remaining_aut > 0 then
        ctx:set(player, component.VAMPIRE, state)
        return
    end

    local finished = state.ritual_kind

    state.ritual_kind = ""
    state.alive = finished == abilities.REVIVIFY
    ctx:set(player, component.VAMPIRE, state)

    if state.alive then
        local classes = require("constants.mutation_classes")
        local transition = require("policy.mutations.transition")

        ctx:emit("mutation", "You return to life.")
        transition.grant(ctx, player, mutations.MUT_FRAIL,
            classes.TEMPORARY, false)
    else
        ctx:emit("mutation", "You become bloodless.")
    end

    local forms = require("policy.magic.effects.forms.player")

    if ctx:has(player, component.PLAYER_FORM) then
        forms.finish(ctx, player)
    end

    forms.rescale_health(ctx, player, forms.max_hp(ctx, player))
end

function vampire.validate(ctx, player)
    local has_mutation = levels.base(ctx, player,
        mutations.MUT_VAMPIRISM) > 0
    local state = ctx:get(player, component.VAMPIRE)

    if has_mutation ~= (state ~= nil) then
        error("invalid Vampire blood state")
    end

    if not state then
        return
    end

    if state.ritual_remaining_aut < 0 or
        state.ritual_remaining_aut > RITUAL_AUT or
        state.ritual_remaining_aut % AUT_PER_RITUAL_TURN ~= 0 or
        (state.ritual_kind == "") ~= (state.ritual_remaining_aut == 0) then
        error("invalid Vampire blood ritual")
    end

    if state.ritual_kind ~= "" and
        state.ritual_kind ~= abilities.EXSANGUINATE and
        state.ritual_kind ~= abilities.REVIVIFY then
        error("unknown Vampire blood ritual")
    end

    if state.ritual_kind == abilities.EXSANGUINATE and not state.alive or
        state.ritual_kind == abilities.REVIVIFY and state.alive then
        error("Vampire blood ritual disagrees with blood state")
    end
end

return vampire
