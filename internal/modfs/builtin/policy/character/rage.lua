-- Example: Berserk start sets the attack bonus and a timer that ends after its last attack.
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
    [command_kind.READ] = true,
}

local noncombat_warnings = {
    [2] = "You feel a strong urge to attack something.",
    [4] = "You feel your anger nearly subside.",
    [6] = "Your blood rage is quickly leaving you.",
}

-- Read the single Berserk component shared by HP scaling and action restrictions.
local function state(ctx, player)
    return ctx:get(player, component.RAGE)
end

-- Update an existing rage component or create it on first activation.
local function save(ctx, player, value)
    if ctx:has(player, component.RAGE) then
        ctx:set(player, component.RAGE, value)
    else
        ctx:add(player, component.RAGE, value)
    end
end

-- Require positive remaining aut; cooldown alone does not count as Berserk.
function rage.active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.remaining_aut > 0
end

-- Attack and spell callers consult this gate while Berserk is active; the status owns duration separately.
function rage.command_restriction(ctx, player, kind)
    if forbidden_commands[kind] and rage.active(ctx, player) then
        return "You are too berserk!"
    end

    return nil
end

-- Apply the source fifty-percent maximum-HP increase only during active rage.
function rage.scale_hp(ctx, player, base)
    if rage.active(ctx, player) then
        return math.max(1, math.floor(base * 3 / 2))
    end

    return base
end

-- A new Berserk attempt checks shared body and status gates before rolling.
-- Only involuntary rage checks Clarity; deliberate god rage and potions are
-- allowed through that one gate, as in the source can_go_berserk contract.
function rage.can_begin(ctx, player, intentional, potion)
    local value = state(ctx, player)

    if value and (value.remaining_aut > 0 or value.cooldown_aut > 0) then
        return false
    end

    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)
    local status = ctx:get(player, component.PLAYER_STATUS)
    local fear = ctx:get(player, component.PLAYER_FEAR)
    local mesmerism = ctx:get(player, component.PLAYER_MESMERISM)

    local forms = require("policy.magic.effects.forms.player")

    return not traits.stasis(species) and not forms.stasis(ctx, player) and
        species.undead_type ~= undead_states.UNDEAD and
        not (status and status.death_door_aut > 0) and
        not (fear and fear.remaining_aut > 0) and
        not (mesmerism and mesmerism.remaining_aut > 0 and
            require("policy.character.player_mesmerism").any(ctx, player)) and
        (intentional or potion or
            effects.sum(ctx, player, capabilities.CLARITY) == 0)
end

-- Persist the initial rage state before action restrictions or HP scaling read it.
function rage.begin(ctx, player, stream, intentional, potion)
    if not rage.can_begin(ctx, player, intentional, potion) then
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

-- A landed melee action resets the no-combat penalty counter.
function rage.melee(ctx, player)
    local value = state(ctx, player)

    if not value or value.remaining_aut <= 0 then
        return
    end

    value.attacked_this_turn = true
    value.noncombat_actions = 0
    save(ctx, player, value)
end

-- Restore scaled vitals and start exhaustion after the rage timer ends.
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

-- Duration and cooldown advance on elapsed aut, not a fixed number of commands.
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

-- Reject impossible saved duration and cooldown combinations at restore.
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
