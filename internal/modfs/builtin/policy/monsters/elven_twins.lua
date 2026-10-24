-- Dowan and Duvessa are a linked pair even after one has been polymorphed.
-- The first saved original class, not its current appearance, identifies
-- which twin another source action must affect.
local component = require("constants.component")
local causes = require("constants.elven_twin")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local boons = require("policy.combat.monster_support.boons")
local death_hooks = require("policy.combat.death_hooks")
local enchantments = require("constants.monster_enchantment")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local invisibility = require("policy.potions.invisibility")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local twins = {}

-- Read the original class when polymorph replaced the visible body.
local function class(ctx, entity)
    local form = ctx:get(entity, component.MONSTER_POLYMORPH)

    if form and form.original_kind_id ~= "" then
        return form.original_kind_id
    end

    local actor = ctx:get(entity, component.ACTOR)

    return actor and actor.kind_id or nil
end

-- Source monster_iterator visits the current floor. A death hook passes
-- its former floor after spatial removal; normal contacts read position.
function twins.other(ctx, entity, level_id)
    local own = class(ctx, entity)
    local wanted
    local origin = ctx:get(entity, component.POSITION)
    local floor = level_id or origin and origin.level_id

    if not floor then
        return nil
    end

    if own == monsters.MONS_DUVESSA then
        wanted = monsters.MONS_DOWAN
    elseif own == monsters.MONS_DOWAN then
        wanted = monsters.MONS_DUVESSA
    else
        return nil
    end

    for _, candidate in ipairs(ctx:query({
        component.ACTOR,
        component.HEALTH,
        component.POSITION,
    })) do
        local health = ctx:get(candidate, component.HEALTH)
        local position = ctx:get(candidate, component.POSITION)

        if candidate ~= entity and health.current > 0 and
            position.level_id == floor and
            class(ctx, candidate) == wanted then
            return candidate
        end
    end

    return nil
end

-- Source defers the power change when the survivor cannot presently see
-- the player. Rechecking at an ordinary decision activates it later.
function twins.maybe_energize(ctx, survivor)
    local grief = ctx:get(survivor, component.MONSTER_ELVEN_TWIN)

    if not grief or not grief.pending then
        return false
    end

    local position = ctx:get(survivor, component.POSITION)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)

    if not position or not player_position or
        position.level_id ~= player_position.level_id or
        not invisibility.visible_to(ctx, player, survivor) or
        not ctx:visible(position.level_id, position.x, position.y,
            7, player_position.x, player_position.y) then
        return false
    end

    local original = class(ctx, survivor)

    if original == monsters.MONS_DUVESSA then
        if not allegiance.can_berserk(ctx, survivor) then
            return false
        end

        allegiance.start_permanent_berserk(ctx, survivor)
    elseif original == monsters.MONS_DOWAN then
        boons.haste(ctx, survivor,
            enchantments.INFINITE_DURATION_AUT)

        local actor = ctx:get(survivor, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        ctx:emit("monster", "The " .. definition.name ..
            " seems to find hidden reserves of power!")
    else
        error("non-twin has a pending elven grief response")
    end

    grief.pending = false
    grief.energized = true
    ctx:set(survivor, component.MONSTER_ELVEN_TWIN, grief)

    return true
end

-- A dead or banished sibling changes the living twin only once. The
-- marker retains a stair-following allowance for the later travel domain.
function twins.grieve(ctx, departed, _, position, cause)
    local survivor = twins.other(ctx, departed, position.level_id)

    if not survivor then
        return false
    end

    local targets = require("policy.ai.targets")

    -- A neutral twin's departure is still a peace conversion, provided
    -- it was not a Jiyva slime. The partner may have missed the initial
    -- same-floor conversion after moving or reappearing independently.
    if targets.real_attitude(ctx, departed) == attitudes.NEUTRAL and
        not allegiance.frenzied(ctx, departed) and
        not ctx:has(departed, component.JIYVA_SLIME) then
        require("policy.religion.elyvilon.pacification")
            .convert_linked(ctx, survivor)

        return false
    end

    if targets.real_attitude(ctx, survivor) ==
        attitudes.GOOD_NEUTRAL or
        ctx:has(survivor, component.MONSTER_ELVEN_TWIN) then
        return false
    end

    ctx:add(survivor, component.MONSTER_ELVEN_TWIN, {
        grieved = true,
        pending = true,
        energized = false,
        can_climb = true,
        cause = cause,
    })

    twins.maybe_energize(ctx, survivor)

    return true
end

-- The shared death-hook registry supplies the original floor before the
-- dying actor loses its position. Ordinary kills and deaths both count.
function twins.on_death(ctx, departed, definition, position)
    twins.grieve(ctx, departed, definition, position, causes.DEATH)

    return false
end

-- A temporary slot projection preserves the committed catalog for any
-- other Dowan. Source rewrites three slots after Duvessa leaves.
function twins.spellbook(ctx, actor, book)
    local grief = ctx:get(actor, component.MONSTER_ELVEN_TWIN)
    local body = ctx:get(actor, component.ACTOR)

    if not grief or not grief.grieved or not book or
        not body or body.kind_id ~= monsters.MONS_DOWAN then
        return book
    end

    if #book.slots < 4 then
        error("grieving Dowan has fewer than four spell slots")
    end

    local changed = {}

    for key, value in pairs(book) do
        changed[key] = value
    end

    changed.slots = {}

    for index, slot in ipairs(book.slots) do
        local copy = {}

        for key, value in pairs(slot) do
            copy[key] = value
        end

        changed.slots[index] = copy
    end

    changed.slots[1].spell_id = spells.SPELL_STONE_ARROW
    changed.slots[2].spell_id = spells.SPELL_THROW_ICICLE
    changed.slots[4].spell_id = spells.SPELL_BLINK

    return changed
end

-- A forged grief component could otherwise grant a rat permanent speed
-- or let a dead sibling resume its pending response after restore.
function twins.validate(ctx)
    for _, entity in ipairs(ctx:query({
        component.MONSTER_ELVEN_TWIN,
    })) do
        local grief = ctx:get(entity, component.MONSTER_ELVEN_TWIN)
        local health = ctx:get(entity, component.HEALTH)
        local position = ctx:get(entity, component.POSITION)
        local original = class(ctx, entity)
        local proper_twin = original == monsters.MONS_DUVESSA or
            original == monsters.MONS_DOWAN
        local cause = grief.cause == causes.DEATH or
            grief.cause == causes.BANISHMENT or
            grief.cause == causes.DUEL

        if not proper_twin or not health or health.current <= 0 or
            not position or not grief.grieved or not grief.can_climb or
            grief.pending == grief.energized or not cause then
            error("invalid elven twin grief on " .. ctx:id(entity))
        end
    end
end

death_hooks.add("monster.elven_twin", twins.on_death)

return twins
