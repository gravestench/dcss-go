-- Source: ability.cc vampire abilities and delay.cc blood rituals.
local abilities = require("ids.abilities")
local component = require("constants.component")
local attributes = require("policy.character.attributes")
local forms = require("policy.magic.effects.forms.player")
local mutations = require("ids.mutations")
local registry = require("policy.abilities.registry")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local vampire = require("policy.character.vampire")

local ritual = {}

function ritual.can_exsanguinate(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)

    return state ~= nil and state.alive and
        state.ritual_remaining_aut == 0
end

function ritual.can_revivify(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)

    return state ~= nil and not state.alive and
        state.ritual_remaining_aut == 0
end

function ritual.prepare_exsanguinate(ctx, player)
    if not ritual.can_exsanguinate(ctx, player) then
        return "You cannot exsanguinate now."
    end

    if ctx:has(player, component.PLAYER_FORM) then
        return forms.end_rejection(ctx, player)
    end
end

function ritual.prepare_revivify(ctx, player)
    if not ritual.can_revivify(ctx, player) then
        return "You cannot revivify now."
    end

    if ctx:has(player, component.PLAYER_FORM) then
        return forms.end_rejection(ctx, player)
    end
end

function ritual.resolve_exsanguinate(ctx, player)
    vampire.begin(ctx, player, abilities.EXSANGUINATE)
end

function ritual.resolve_revivify(ctx, player)
    vampire.begin(ctx, player, abilities.REVIVIFY)
end

function ritual.can_become_bat(ctx, player)
    local state = ctx:get(player, component.VAMPIRE)
    local form = ctx:get(player, component.PLAYER_FORM)

    return state ~= nil and not state.alive and
        state.ritual_remaining_aut == 0 and
        (not form or form.form_id ~= "bat")
end

function ritual.prepare_bat(ctx, player, input)
    if not ritual.can_become_bat(ctx, player) then
        return "You cannot assume Bat Form now."
    end

    local magic = ctx:get(player, component.MAGIC)

    if not magic or magic.current < 2 then
        return "You do not have enough magic to become a bat."
    end

    local rejection = forms.rejection(ctx, player, abilities.BAT_FORM)

    if rejection then
        return rejection
    end

    if ritual.bat_confirmation_needed(ctx, player) and not input.forced then
        return ritual.bat_confirmation_message(ctx, player)
    end

    return nil
end

function ritual.bat_confirmation_needed(ctx, player)
    local current = attributes.current(ctx, player)

    return current.strength <= 2 or current.intelligence <= 2 or
        current.dexterity <= 2
end

function ritual.bat_confirmation_message()
    return "Bat Form may drain a stat to zero. Continue?"
end

function ritual.resolve_bat(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)
    local chance = math.max(0, 45 - 2 * progress.level)

    if ctx:random("mutation", 100) < chance then
        ctx:emit("mutation", "You fail to transform into a bat.")
        return
    end

    local magic = ctx:get(player, component.MAGIC)

    magic.current = magic.current - 2
    ctx:set(player, component.MAGIC, magic)
    forms.cast(ctx, player, abilities.BAT_FORM, 100)

    for _, field in ipairs(stats.ORDER) do
        stat_loss.drain(ctx, player, field, 2)
    end
end

registry.add(abilities.EXSANGUINATE, {
    mutation_id = mutations.MUT_VAMPIRISM,
    name = "Exsanguinate",
    available = ritual.can_exsanguinate,
    prepare = ritual.prepare_exsanguinate,
    resolve = ritual.resolve_exsanguinate,
})

registry.add(abilities.REVIVIFY, {
    mutation_id = mutations.MUT_VAMPIRISM,
    name = "Revivify",
    available = ritual.can_revivify,
    prepare = ritual.prepare_revivify,
    resolve = ritual.resolve_revivify,
})

registry.add(abilities.BAT_FORM, {
    mutation_id = mutations.MUT_VAMPIRISM,
    name = "Bat Form",
    min_level = 2,
    available = ritual.can_become_bat,
    confirmation_needed = ritual.bat_confirmation_needed,
    confirmation_message = ritual.bat_confirmation_message,
    prepare = ritual.prepare_bat,
    resolve = ritual.resolve_bat,
})

return ritual
