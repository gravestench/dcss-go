local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local records = require("policy.character.spell_records")
local player_scope = require("policy.magic.player_scope")
local traits = require("policy.character.traits")
local availability = require("policy.character.skill_availability")

local learning = {}

-- Source: player.cc:player_total_spell_levels and player_spell_levels.
-- The scaled Spellcasting skill includes progress toward the next level.
function learning.levels(ctx, player)
    local character = ctx:get(player, "core.player")
    local progress = ctx:get(player, "core.progression")
    local skills = ctx:get(player, "core.skills")

    if not character or not progress or not skills then
        error("player lacks spell-level state")
    end

    local species = catalog.get("species", character.species_id)
    local spellcasting = 0

    for _, skill in ipairs(skills.entries) do
        if skill.id == "SK_SPELLCASTING" then
            local aptitude = formulas.effective_skill_aptitude(ctx, player,
                species, skill.id)
            spellcasting = formulas.scaled_skill(skill, 2, aptitude)
            break
        end
    end

    local total = math.min(99, progress.level - 1 + spellcasting)
    local used = 0

    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.known_slot > 0 then
            used = used + catalog.get("spells", entry.state.spell_id).level
        end
    end

    return total, math.max(0, total - used)
end

-- Source: spl-book.cc:_learn_spell_checks. This preflight is read-only so
-- a rejected command cannot spend an action or change the spell record.
function learning.cannot_begin(ctx, player, spell_id)
    if player_scope.of(spell_id) ~= "book" then
        return "You cannot memorise that spell."
    end

    local entry = records.find(ctx, player, spell_id)

    if not entry or not entry.state.in_library then
        return "That spell is not in your library."
    end

    if entry.state.known_slot > 0 then
        return "You already know that spell!"
    end

    local casting = ctx:get(player, "character.spellcasting")

    if not casting or casting.learning_remaining > 0 then
        return "You are already memorising a spell."
    end

    local character = ctx:get(player, "core.player")
    local progress = ctx:get(player, "core.progression")
    local species = catalog.get("species", character.species_id)
    local spell = catalog.get("spells", spell_id)

    if availability.forbidden_spell(ctx, player, spell) then
        return "You cannot memorise that spell."
    end

    if not traits.start_spell_usable(ctx, player, species, spell_id) then
        return "You cannot memorise that spell."
    end

    if progress.level < spell.level then
        return "You're too inexperienced to learn that spell!"
    end

    local known = 0

    for _, record in ipairs(records.list(ctx, player)) do
        if record.state.known_slot > 0 then
            known = known + 1
        end
    end

    if known >= 52 then
        return "Your head is already too full of spells!"
    end

    local _, available = learning.levels(ctx, player)

    if available < spell.level then
        return "You can't memorise that many levels of magic yet!"
    end

    return nil
end

-- Source: spl-book.cc:learn_spell. The spell becomes known only when the
-- memorisation delay finishes.
function learning.begin(ctx, player, spell_id)
    local rejection = learning.cannot_begin(ctx, player, spell_id)

    if rejection then
        return { message = rejection }
    end

    local casting = ctx:get(player, "character.spellcasting")
    local spell = catalog.get("spells", spell_id)

    casting.learning_spell_id = spell_id
    casting.learning_remaining = spell.level
    ctx:set(player, "character.spellcasting", casting)

    return { started = true }
end

function learning.advance(ctx, player, intent)
    if intent.kind == 14 then
        local result = learning.begin(ctx, player, intent.spell_id)

        if not result.started then
            error(result.message)
        end

        return
    end

    local casting = ctx:get(player, "character.spellcasting")

    if intent.kind ~= 6 or not casting or
        casting.learning_remaining == 0 then
        return
    end

    casting.learning_remaining = casting.learning_remaining - 1

    if casting.learning_remaining > 0 then
        ctx:set(player, "character.spellcasting", casting)
        return
    end

    local spell_id = casting.learning_spell_id
    local entry = records.find(ctx, player, spell_id)

    if not entry or entry.state.known_slot > 0 then
        error("invalid memorisation completion for " .. spell_id)
    end

    entry.state.known_slot = records.next_slot(ctx, player, "known_slot")
    entry.state.letter_slot = records.next_slot(ctx, player, "letter_slot")
    ctx:set(entry.entity, "character.spell", entry.state)
    casting.learning_spell_id = ""
    ctx:set(player, "character.spellcasting", casting)

    local spell = catalog.get("spells", spell_id)
    ctx:emit("spell-learn", "You finish memorising " .. spell.name .. ".")
end

function learning.interrupt(ctx, player)
    local casting = ctx:get(player, "character.spellcasting")

    if not casting or casting.learning_remaining == 0 then
        return "You are not memorising a spell."
    end

    casting.learning_spell_id = ""
    casting.learning_remaining = 0
    ctx:set(player, "character.spellcasting", casting)

    -- Source: delay.cc:MemoriseDelay::try_interrupt.
    return "Your memorisation is interrupted."
end

-- Source: spl-util.cc:del_spell_from_memory. Library discovery remains after
-- the memorised slot and its assigned letter are freed.
function learning.forget(ctx, player, spell_id)
    local entry = records.find(ctx, player, spell_id)

    if not entry or entry.state.known_slot == 0 then
        return { message = "You do not know that spell." }
    end

    entry.state.known_slot = 0
    entry.state.letter_slot = 0
    ctx:set(entry.entity, "character.spell", entry.state)

    local casting = ctx:get(player, "character.spellcasting")

    if casting.last_spell_id == spell_id then
        casting.last_spell_id = ""
        ctx:set(player, "character.spellcasting", casting)
    end

    local spell = catalog.get("spells", spell_id)
    ctx:emit("spell-forget", "Your memory of " .. spell.name .. " unravels.")

    return { forgotten = true }
end

function learning.spell_levels(ctx)
    local total, available = learning.levels(ctx, ctx:player())

    return {
        total = total,
        available = available,
    }
end

register.policy({
    id = "magic.spell_levels",
    run = learning.spell_levels,
})

function learning.begin_learning(ctx, input)
    return learning.begin(ctx, ctx:player(), input.spell_id)
end

register.policy({
    id = "magic.begin_learning",
    run = learning.begin_learning,
})

function learning.forget_policy(ctx, input)
    return learning.forget(ctx, ctx:player(), input.spell_id)
end

register.policy({
    id = "magic.forget",
    run = learning.forget_policy,
})

return learning
