-- Silver always adds a small fragment of damage. Source beam.cc increases
-- that bonus for a shapechanged player or for accumulated mutations; the
-- pinned source's player::how_chaotic is a stub returning zero.
local component = require("constants.component")
local forms = require("constants.form_ids")
local health = require("policy.combat.player_health")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local monsters = require("ids.monsters")
local flavours = require("constants.attack_flavours")
local gods = require("constants.gods")

local silver = {}

-- These catalog classes are intrinsically chaotic in monster::known_chaos.
-- A live shifter marker and mutable attack/god facts are checked below.
local chaotic_classes = {
    [monsters.MONS_UGLY_THING] = true,
    [monsters.MONS_VERY_UGLY_THING] = true,
    [monsters.MONS_ABOMINATION_SMALL] = true,
    [monsters.MONS_ABOMINATION_LARGE] = true,
    [monsters.MONS_WRETCHED_STAR] = true,
    [monsters.MONS_KILLER_KLOWN] = true,
    [monsters.MONS_TIAMAT] = true,
    [monsters.MONS_BAI_SUZHEN] = true,
    [monsters.MONS_BAI_SUZHEN_DRAGON] = true,
}

local chaotic_gods = {
    [gods.XOM] = true,
    [gods.MAKHLEB] = true,
    [gods.LUGONU] = true,
    [gods.JIYVA] = true,
}

-- Minor hand changes, Lich, and Shadow Form keep the source body shape.
local unaltered = {
    [forms.APPENDAGE] = true,
    [forms.BLADE_HANDS] = true,
    [forms.LICH] = true,
    [forms.SHADOW] = true,
}

local function shapechanged(ctx, player)
    local form = ctx:get(player, component.PLAYER_FORM)

    return form ~= nil and not unaltered[form.form_id]
end

-- Innate levels count for Demonspawn, while another species' ordinary
-- physiology does not. Acquired and temporary mutation levels count for all.
local function mutation_levels(ctx, player)
    local choice = ctx:get(player, component.PLAYER)
    local innate = choice.species_id == species.SP_DEMONSPAWN
    local total = 0

    -- In the pinned source, player::how_mutated subtracts the saved Ru
    -- count inside its loop over every mutation enum value. A positive
    -- count therefore suppresses the mutation-based silver term for a
    -- Demonspawn. Keep that observable rule without repeating a large
    -- source loop in every projectile hit.
    if innate then
        local ru = ctx:get(player, component.RELIGION_RU)

        if ru and ru.sacrifice_mutations > 0 then
            return 0
        end
    end

    for _, entry in ipairs(records.list(ctx, player)) do
        local state = entry.state

        total = total + state.acquired + state.temporary

        if innate then
            total = total + state.innate
        end
    end

    return total
end

-- Keep source's minimum one-plus-a-third roll even when the victim has no
-- silver vulnerability. The status-dependent term can only raise it.
function silver.apply(ctx, attacker, _, _, damage)
    local player = ctx:player()
    local minimum = 1 + math.floor(
        ctx:random(streams.MELEE, math.max(1, damage)) / 3)
    local vulnerable = 0

    if shapechanged(ctx, player) then
        vulnerable = math.floor(damage * 3 / 4)
    else
        local multiplier = math.min(75, 5 * mutation_levels(ctx, player))

        vulnerable = math.floor(damage * multiplier / 100)
    end

    if vulnerable > minimum then
        ctx:emit("combat", "The silver sears you!")
    end

    health.damage(ctx, player, math.max(minimum, vulnerable),
        false, attacker)
end

-- Silver hurts a chaotic monster for three quarters of base damage, but
-- even an ordinary reflected victim receives the minimum fragment roll.
local function chaotic_monster(ctx, monster, definition)
    if chaotic_classes[definition.id] or
        definition.genus_id == monsters.MONS_DEMONSPAWN or
        ctx:has(monster, component.MONSTER_SHAPESHIFTER) then
        return true
    end

    for _, attack in ipairs(definition.attacks or {}) do
        if attack.flavour == flavours.MUTATE or
            attack.flavour == flavours.CHAOTIC then
            return true
        end
    end

    local overrides = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)
    local god_id = overrides and overrides.god_id or definition.god_id

    return chaotic_gods[god_id] == true
end

-- The caller applies this extra amount after the reflected base hit.
function silver.monster_bonus(ctx, monster, definition, damage)
    local minimum = 1 + math.floor(
        ctx:random(streams.MELEE, math.max(1, damage)) / 3)
    local vulnerability = chaotic_monster(ctx, monster, definition) and
        math.floor(damage * 3 / 4) or 0

    if vulnerability > 0 then
        ctx:emit("combat", "The silver sears the " ..
            definition.name .. "!")
    end

    return math.max(minimum, vulnerability)
end

return silver
