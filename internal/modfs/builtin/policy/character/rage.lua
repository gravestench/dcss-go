-- Source: player-act.cc:go_berserk, player.cc:player_end_berserk,
-- and main.cc:_do_berserk_no_combat_penalty.
local catalog = require("policy.catalog")
local command_kind = require("constants.command_kind")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local formulas = require("policy.character.formulas")
local slow = require("policy.character.slow")
local traits = require("policy.character.traits")
local undead_states = require("constants.undead_states")

local rage = {}

-- Source: spl-cast.cc, spl-book.cc, throw.cc, and item-use.cc. Wielding
-- remains possible while berserk; the source only warns for launchers.
local forbidden_commands = {
    [command_kind.QUAFF] = true,
    [command_kind.WEAR] = true,
    [command_kind.TAKE_OFF] = true,
    [command_kind.FIRE] = true,
    [command_kind.THROW] = true,
    [command_kind.MEMORISE] = true,
    [command_kind.CAST] = true,
    [command_kind.FORCE_CAST] = true,
    [command_kind.EVOKE_WAND] = true,
}

local noncombat_warnings = {
    [2] = "You feel a strong urge to attack something.",
    [4] = "You feel your anger nearly subside.",
    [6] = "Your blood rage is quickly leaving you.",
}

local function state(ctx, player)
    return ctx:get(player, component.RAGE)
end

local function save(ctx, player, value)
    if ctx:has(player, component.RAGE) then
        ctx:set(player, component.RAGE, value)
    else
        ctx:add(player, component.RAGE, value)
    end
end

function rage.active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.remaining_aut > 0
end

function rage.command_restriction(ctx, player, kind)
    if forbidden_commands[kind] and rage.active(ctx, player) then
        return "You are too berserk!"
    end

    return nil
end

function rage.scale_hp(ctx, player, base)
    if rage.active(ctx, player) then
        return math.max(1, math.floor(base * 3 / 2))
    end

    return base
end

function rage.can_begin(ctx, player)
    local value = state(ctx, player)

    if value and (value.remaining_aut > 0 or value.cooldown_aut > 0) then
        return false
    end

    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local status = ctx:get(player, component.PLAYER_STATUS)

    local forms = require("policy.magic.effects.forms.player")

    return not traits.stasis(species) and not forms.stasis(ctx, player) and
        species.undead_type ~= undead_states.UNDEAD and
        not (status and status.death_door_aut > 0) and
        effects.sum(ctx, player, capabilities.CLARITY) == 0
end

function rage.begin(ctx, player, stream)
    if not rage.can_begin(ctx, player) then
        return false
    end

    local health = ctx:get(player, component.HEALTH)
    local regeneration = ctx:get(player, component.REGENERATION)

    if not health or not regeneration or health.max <= 0 then
        error("rage requires live player health and regeneration")
    end

    stream = stream or "mutation"

    local average = math.floor((ctx:random(stream, 19) +
        ctx:random(stream, 20)) / 2)
    local turns = math.floor((20 + average) / 2)
    local value = {
        remaining_aut = turns * 10,
        cooldown_aut = 0,
        noncombat_actions = 0,
        attacked_this_turn = true,
    }

    formulas.rescale_health(health, regeneration,
        math.floor(health.max * 3 / 2))
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.REGENERATION, regeneration)
    save(ctx, player, value)

    ctx:emit("duration", "A red film seems to cover your vision as you go berserk!")
    ctx:emit("duration", "You feel yourself moving faster!")
    ctx:emit("duration", "You feel mighty!")

    return true
end

function rage.melee(ctx, player)
    local value = state(ctx, player)

    if not value or value.remaining_aut <= 0 then
        return
    end

    value.attacked_this_turn = true
    value.noncombat_actions = 0
    save(ctx, player, value)
end

local function finish(ctx, player, value)
    local health = ctx:get(player, component.HEALTH)
    local regeneration = ctx:get(player, component.REGENERATION)
    local forms = require("policy.magic.effects.forms.player")

    formulas.rescale_health(health, regeneration,
        forms.max_hp(ctx, player))
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.REGENERATION, regeneration)

    local turns = 12 + (ctx:random("mutation", 12) + 1) +
        (ctx:random("mutation", 12) + 1)

    value.remaining_aut = 0
    value.cooldown_aut = turns * 20
    value.noncombat_actions = 0
    value.attacked_this_turn = false
    save(ctx, player, value)
    slow.apply(ctx, player, turns)

    ctx:emit("duration", "You are no longer berserk.")
    ctx:emit("duration", "You are exhausted.")
end

function rage.tick(ctx, player, aut)
    local value = state(ctx, player)

    if not value or aut <= 0 then
        return
    end

    if value.remaining_aut <= 0 then
        value.cooldown_aut = math.max(0, value.cooldown_aut - aut)

        if value.cooldown_aut == 0 then
            ctx:remove(player, component.RAGE)
            ctx:emit("duration", "You recover from your berserk rage.")
        else
            save(ctx, player, value)
        end

        return
    end

    value.remaining_aut = math.max(0, value.remaining_aut - aut)

    if not value.attacked_this_turn and value.remaining_aut > 0 then
        value.noncombat_actions = value.noncombat_actions + 1

        local warning = noncombat_warnings[value.noncombat_actions]

        if warning then
            ctx:emit("duration", warning)
        end

        value.remaining_aut = math.max(1, value.remaining_aut -
            value.noncombat_actions * 10)
    end

    value.attacked_this_turn = false

    if value.remaining_aut == 0 then
        finish(ctx, player, value)
    else
        save(ctx, player, value)
    end
end

function rage.validate(ctx, player)
    local value = state(ctx, player)

    if not value then
        return
    end

    if value.remaining_aut < 0 or value.cooldown_aut < 0 or
        value.noncombat_actions < 0 or
        (value.remaining_aut > 0 and value.cooldown_aut > 0) or
        (value.remaining_aut == 0 and value.cooldown_aut == 0) or
        (value.remaining_aut == 0 and value.attacked_this_turn) then
        error("invalid player rage state")
    end
end

return rage
