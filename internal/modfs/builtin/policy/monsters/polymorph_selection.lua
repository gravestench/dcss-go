-- Source: mon-poly.cc _valid_type_morph, init_poly_set, and monster_polymorph.
-- This policy owns target selection; the spell policy owns the body change.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local habitats = require("constants.monster_habitats")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local demon_tiers = require("constants.monster_demon_tiers")

local selection = {}
local definitions = catalog.all(categories.MONSTERS)
local weighted_by_body = {}
local pool_by_terrain = {}

local forbidden_flags = {
    flags.UNFINISHED,
    "M_CANT_SPAWN",
    "M_NO_POLY_TO",
    flags.UNIQUE,
    flags.NO_THREAT,
    flags.NO_EXP_GAIN,
    flags.GHOST_DEMON,
    flags.PROJECTILE,
}

-- Source mons_is_statue names these four forms specifically. Other fixed
-- plants may be threatening and are legal morph destinations.
local statue_forms = {
    [monsters.MONS_ORANGE_STATUE] = true,
    [monsters.MONS_OBSIDIAN_STATUE] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_ROXANNE] = true,
}

-- These corpse-derived templates use a selected base monster's body data;
-- source mons_class_is_zombified excludes them as polymorph destinations.
local corpse_templates = {
    [monsters.MONS_ZOMBIE] = true,
    [monsters.MONS_ZOMBIE_SMALL] = true,
    [monsters.MONS_ZOMBIE_LARGE] = true,
    [monsters.MONS_SKELETON] = true,
    [monsters.MONS_SKELETON_SMALL] = true,
    [monsters.MONS_SKELETON_LARGE] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_SIMULACRUM_SMALL] = true,
    [monsters.MONS_SIMULACRUM_LARGE] = true,
    [monsters.MONS_SPECTRAL_THING] = true,
    [monsters.MONS_BOUND_SOUL] = true,
}

-- Catalog lists are data, so absent lists never confer a trait.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- The source requires at least one shared holiness bit before changing body.
local function shares_holiness(source, target)
    for _, value in ipairs(source.holiness or {}) do
        if has(target.holiness, value) then
            return true
        end
    end

    return false
end

-- A preselected form must fit the original body's habitat, not just the
-- current cell. Flying origins can only retain flight in this source rule.
local function matching_habitat(source, target)
    if has(target.flags, flags.FLIES) then
        return true
    end

    if has(source.flags, flags.FLIES) then
        return false
    end

    local old = source.habitat_id
    local new = target.habitat_id

    if old == habitats.LAND then
        return new == habitats.LAND or new == habitats.AMPHIBIOUS or
            new == habitats.AMPHIBIOUS_LAVA
    end

    if old == habitats.WATER then
        return new == habitats.WATER or new == habitats.AMPHIBIOUS
    end

    if old == habitats.LAVA then
        return new == habitats.LAVA or new == habitats.AMPHIBIOUS_LAVA
    end

    return old == new
end

-- RANDOM_MONSTER samples species able to occupy the current tile. The
-- three-form set is not restricted by this tile until the spell is cast.
local function safe_cell(cell, target)
    local habitat = target.habitat_id

    if has(target.flags, flags.FLIES) then
        return true
    end

    if cell == terrain.DNGN_LAVA then
        return habitat == habitats.LAVA or
            habitat == habitats.AMPHIBIOUS_LAVA
    end

    if cell == terrain.DNGN_DEEP_WATER then
        return habitat == habitats.WATER or
            habitat == habitats.AMPHIBIOUS
    end

    return habitat ~= habitats.LAVA and habitat ~= habitats.WATER
end

-- This is the shared source species gate. A shifter's permanent identity
-- prevents it borrowing demons or the opposite permanent shifter variant.
local function eligible_type(source, target, shifter, named_prince)
    if target.status ~= "defined" or target.species_id ~= target.id or
        target.species_id == source.species_id or
        not target.average_hp_10x or target.average_hp_10x <= 0 or
        not target.speed or target.speed <= 0 or
        corpse_templates[target.id] or statue_forms[target.id] or
        not shares_holiness(source, target) then
        return false
    end

    for _, flag in ipairs(forbidden_flags) do
        if has(target.flags, flag) then
            return false
        end
    end

    if shifter then
        if not has(target.holiness, holiness.NATURAL) then
            return false
        end

        if shifter.variant_id == monsters.MONS_SHAPESHIFTER and
            target.id == monsters.MONS_GLOWING_SHAPESHIFTER or
            shifter.variant_id == monsters.MONS_GLOWING_SHAPESHIFTER and
            target.id == monsters.MONS_SHAPESHIFTER then
            return false
        end
    end

    if target.id == monsters.MONS_HUMAN and named_prince then
        return false
    end

    return true
end

-- Prince Ribbit keeps his identity through a body change. Source also
-- checks a monster still named Prince Ribbit, so a vault name has the same
-- exclusion even if its current catalog species differs.
local function prince_identity(ctx, monster, source)
    if source.id == monsters.MONS_PRINCE_RIBBIT then
        return true
    end

    if not monster then
        return false
    end

    local form = ctx:get(monster, component.MONSTER_POLYMORPH)
    local overrides = ctx:get(monster, component.VAULT_ACTOR_OVERRIDES)
    local prince = catalog.get(categories.MONSTERS,
        monsters.MONS_PRINCE_RIBBIT)

    return form and
        form.original_kind_id == monsters.MONS_PRINCE_RIBBIT or
        overrides and overrides.custom_name == prince.name or false
end

-- Demon tier is part of both the set's weight and RANDOM_MONSTER's retry
-- condition. Source uses the monster base glyph, including every & lord.
function selection.demon_tier(definition)
    if definition.id == monsters.MONS_ANTAEUS then
        return -1
    end

    return demon_tiers[definition.glyph] or 0
end

-- Keep terrain validation distinct from species eligibility: a previously
-- rolled form can become unsafe when terrain changes before the next cast.
function selection.eligible(ctx, monster, source, target, position, stream)
    local shifter = monster and
        ctx:get(monster, component.MONSTER_SHAPESHIFTER)
    local named_prince = target.id == monsters.MONS_HUMAN and
        prince_identity(ctx, monster, source)

    if not eligible_type(source, target, shifter, named_prince) then
        return false
    end

    -- Source _valid_morph thins the coloured draconians after the species
    -- gate but before the tile gate; the set itself still stores them.
    if target.genus_id == monsters.MONS_DRACONIAN and
        target.id ~= monsters.MONS_DRACONIAN and
        ctx:random(stream or streams.SPELL, 9) ~= 0 then
        return false
    end

    local cell = ctx:cell(position.level_id, position.x, position.y)

    return safe_cell(cell, target)
end

-- Uniform species sampling happens before eligibility checks, as in
-- random_monster_at_grid; rejected draws still spend retry RNG.
function selection.pool(ctx, position)
    local cell = ctx:cell(position.level_id, position.x, position.y)
    local cached = pool_by_terrain[cell]

    if cached then
        return cached
    end

    local pool = {}

    for _, definition in ipairs(definitions) do
        if definition.status == "defined" and
            definition.species_id == definition.id and
            safe_cell(cell, definition) then
            pool[#pool + 1] = definition
        end
    end

    pool_by_terrain[cell] = pool

    return pool
end

-- One weight formula serves creation and save validation, so a forged form
-- cannot pass merely because it is a legal species at an impossible distance.
local function form_weight(source, target, original_tier)
    -- Generated corpse templates omit zero HD in the Lua catalog. Source
    -- mons_power reads that class value as zero, not the chosen corpse base.
    local source_hd = source.hd or 0
    local target_hd = target.hd or 0
    local hd_delta = math.abs(source_hd - target_hd)

    if target_hd > source_hd then
        hd_delta = hd_delta * 2
    end

    local tier_delta = math.abs(original_tier -
        selection.demon_tier(target))
    local distance = hd_delta + tier_delta

    if distance > 8 then
        return nil
    end

    return 2 ^ (8 - distance)
end

-- Source init_poly_set weights near-HD forms and demon-tier proximity, then
-- draws up to three distinct species without replacement.
local function roll_set(ctx, monster, source)
    local original_tier = selection.demon_tier(source)

    if original_tier == -1 then
        return nil
    end

    local shifter = ctx:get(monster, component.MONSTER_SHAPESHIFTER)
    local named_prince = prince_identity(ctx, monster, source)
    local key = source.id .. ":" .. (shifter and shifter.variant_id or "") ..
        ":" .. tostring(named_prince)
    local weighted = weighted_by_body[key]

    if not weighted then
        weighted = {}

        for _, definition in ipairs(definitions) do
            if eligible_type(source, definition, shifter, named_prince) and
                matching_habitat(source, definition) then
                local weight = form_weight(source, definition,
                    original_tier)

                if weight then
                    weighted[#weighted + 1] = {
                        id = definition.id,
                        weight = weight,
                    }
                end
            end
        end

        weighted_by_body[key] = weighted
    end

    -- Draws remove choices, so copy only the small reference list while
    -- reusing immutable catalog eligibility and weights for this body.
    local choices = {}

    for index, choice in ipairs(weighted) do
        choices[index] = choice
    end

    local forms = {}

    for _ = 1, math.min(3, #choices) do
        local total = 0

        for _, choice in ipairs(choices) do
            total = total + choice.weight
        end

        local draw = ctx:random(streams.POLYMORPH_SET, total)

        for index, choice in ipairs(choices) do
            draw = draw - choice.weight

            if draw < 0 then
                forms[#forms + 1] = choice.id
                table.remove(choices, index)
                break
            end
        end
    end

    return forms
end

-- Ordinary placement calls this once. A restored old save can call it on
-- first use without changing the saved actor's other state.
function selection.initialize(ctx, monster, source)
    if ctx:has(monster, component.MONSTER_POLYMORPH_SET) then
        return
    end

    local forms = roll_set(ctx, monster, source)

    if forms then
        ctx:add(monster, component.MONSTER_POLYMORPH_SET, {
            forms = forms,
        })
    end
end

-- A successful body change invalidates the old set and rolls for the new
-- species. Source change_monster_type does this even for fixed targets.
function selection.replace(ctx, monster, source)
    local forms = roll_set(ctx, monster, source)

    if not forms then
        if ctx:has(monster, component.MONSTER_POLYMORPH_SET) then
            ctx:remove(monster, component.MONSTER_POLYMORPH_SET)
        end

        return
    end

    local value = { forms = forms }

    if ctx:has(monster, component.MONSTER_POLYMORPH_SET) then
        ctx:set(monster, component.MONSTER_POLYMORPH_SET, value)
    else
        ctx:add(monster, component.MONSTER_POLYMORPH_SET, value)
    end
end

-- SAME power uniformly draws one existing form. The caller validates the
-- current cell before mutation; a failed request keeps the set unchanged.
function selection.pick(ctx, monster, stream)
    local stored = ctx:get(monster, component.MONSTER_POLYMORPH_SET)

    if not stored then
        local actor = ctx:get(monster, component.ACTOR)
        local source = catalog.get(categories.MONSTERS, actor.kind_id)

        selection.initialize(ctx, monster, source)
        stored = ctx:get(monster, component.MONSTER_POLYMORPH_SET)
    end

    if not stored or #stored.forms == 0 then
        return nil
    end

    local index = ctx:random(stream or streams.SPELL, #stored.forms) + 1

    return catalog.get(categories.MONSTERS, stored.forms[index])
end

-- Save validation rejects tampering and stale body sets without requiring a
-- particular RNG seed or discovery order to reconstruct the exact picks.
function selection.validate(ctx, monster, source)
    local stored = ctx:get(monster, component.MONSTER_POLYMORPH_SET)

    if not stored then
        return
    end

    if #stored.forms > 3 then
        error("monster polymorph set has more than three forms")
    end

    local seen = {}
    local shifter = ctx:get(monster, component.MONSTER_SHAPESHIFTER)
    local named_prince = prince_identity(ctx, monster, source)
    local original_tier = selection.demon_tier(source)

    if original_tier == -1 then
        error("immune monster has a polymorph set")
    end

    for _, kind_id in ipairs(stored.forms) do
        local target = catalog.get(categories.MONSTERS, kind_id)

        if seen[kind_id] or not eligible_type(source, target, shifter,
            named_prince) or
            not matching_habitat(source, target) or
            not form_weight(source, target, original_tier) then
            error("monster polymorph set has an invalid form")
        end

        seen[kind_id] = true
    end
end

return selection
