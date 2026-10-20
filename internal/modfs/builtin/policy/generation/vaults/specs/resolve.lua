-- Example: An authored monster name ignores a removed catalog entry during resolution.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local choice = require("policy.generation.vaults.specs.choice")
local random_monsters = require("policy.generation.vaults.specs.random_monsters")
local random_items = require("policy.generation.vaults.specs.random_items")
local pool = require("policy.population.pool")
local monster_ids = require("ids.monsters")
local item_ids = require("ids.items")
local item_quality = require("constants.vault_item_quality")
local colours = require("constants.vault_colours")
local monster_flags = require("constants.monster_flags")
local schools = require("constants.spell_schools")
local slime_blob = require("policy.monsters.slime_blob")

local resolve = {}
local names_by_category = {}

local random_monster_names = {
    ["common demon"] = true,
    ["any common demon"] = true,
    ["0"] = true,
    ["8"] = true,
    ["9"] = true,
    random_monster = true,
    super_out_of_depth_monster = true,
    moderate_out_of_depth_monster = true,
}

local random_item_names = {
    ["$"] = true,
    ["%"] = true,
    ["*"] = true,
    ["|"] = true,
    random_gold = true,
    random_item = true,
    good_item = true,
    superb_item = true,
    star_item = true,
}

-- A themed random book must name a spell school understood by the same
-- generator used for shop stock. Reject typos during vault catalog loading.
local function valid_discipline(discipline)
    if not discipline then
        return true
    end

    for _, school in pairs(schools) do
        if school == discipline then
            return true
        end
    end

    return false
end

-- Exclude removed catalog entries while resolving authored names.
local function active(definition)
    return definition.status ~= "removed" and
        definition.status ~= "enum_only" and
        not definition.explicitly_removed
end

-- Resolve authored display names through a catalog index instead of assuming IDs.
local function name_index(category)
    local index = names_by_category[category]

    if index then
        return index
    end

    index = {}
    for _, definition in ipairs(catalog.all(category)) do
        if active(definition) then
            local names = { definition.name }

            for _, alias in ipairs(definition.vault_aliases or {}) do
                names[#names + 1] = alias
            end

            for _, name in ipairs(names) do
                if name and name ~= "" then
                    local key = name:lower()
                    local ids = index[key] or {}

                    if ids[#ids] ~= definition.id then
                        ids[#ids + 1] = definition.id
                    end

                    index[key] = ids
                end
            end
        end
    end

    names_by_category[category] = index

    return index
end

-- Reject unknown or ambiguous display names instead of guessing a catalog ID.
-- Source monster names can also belong to internal entities such as the
-- player's shadow. Prefer the sole spawnable profile when that happens;
-- retain an ambiguity error if two ordinary monsters still share a name.
local function spawnable_name_match(ids)
    local chosen

    for _, id in ipairs(ids) do
        local definition = catalog.get(categories.MONSTERS, id)
        local can_spawn = true

        for _, flag in ipairs(definition.flags or {}) do
            if flag == "M_CANT_SPAWN" then
                can_spawn = false
            end
        end

        if can_spawn then
            if chosen then
                return nil
            end

            chosen = id
        end
    end

    return chosen
end

-- Preserve an explicit ambiguity for items or genuinely duplicated
-- spawnable monsters; a player-only profile cannot steal a vault name.
local function find_name(category, name, site)
    local names = name_index(category)
    local ids = names[name:lower()]

    -- Legacy DES sometimes writes a display name with underscores, such as
    -- unseen_horror. Prefer an exact alias, then normalize only for lookup.
    if not ids and name:find("_", 1, true) then
        ids = names[name:gsub("_", " "):lower()]
    end

    if not ids then
        choice.fail(site, name, "unknown " .. category .. " name")
    end

    if #ids > 1 then
        if category == categories.MONSTERS then
            -- A source display name can also identify another form of
            -- the same unique. Prefer the exact species ID before asking
            -- whether the remaining profiles are spawnable.
            local canonical = "MONS_" .. name:upper():gsub(
                "[^A-Z0-9]+", "_"):gsub("^_", ""):gsub("_$", "")

            local exact = false
            local same_forms = true

            for _, id in ipairs(ids) do
                exact = exact or id == canonical
                same_forms = same_forms and
                    (id == canonical or
                        id:sub(1, #canonical + 1) == canonical .. "_")
            end

            if exact and same_forms then
                return canonical
            end

            local chosen = spawnable_name_match(ids)

            if chosen then
                return chosen
            end
        end

        choice.fail(site, name, string.format(
            "ambiguous %s name: %s and %s", category, ids[1], ids[2]))
    end

    return ids[1]
end

-- A DES D:N place overrides the current floor for this resolver request.
local function source_depth(selected, depth)
    local value = selected.place and selected.place:match("^D:(%d+)$")

    return tonumber(value) or depth
end

-- Random corpse requests filter to species capable of leaving the requested remains.
local function generic_corpse_species(ctx, depth, skeleton, site)
    local rows = pool.at_depth(depth)
    local eligible = {}
    local total = 0

    for _, row in ipairs(rows) do
        local definition = catalog.get(categories.MONSTERS, row.id)
        local can_leave_skeleton = true

        for _, flag in ipairs(definition.flags or {}) do
            can_leave_skeleton = can_leave_skeleton and flag ~= "M_NO_SKELETON"
        end

        if definition.leaves_corpse and (not skeleton or can_leave_skeleton) then
            eligible[#eligible + 1] = row
            total = total + row.weight
        end
    end

    if total == 0 then
        choice.fail(site, "skeleton", "no eligible corpse species at depth " .. depth)
    end

    return pool.pick(ctx, eligible, total)
end

-- Check skeleton eligibility for a named monster before materializing remains.
local function named_corpse_species(name, skeleton, site)
    local id = find_name(categories.MONSTERS, name, site)
    local definition = catalog.get(categories.MONSTERS, id)
    local invalid = not definition.leaves_corpse

    if skeleton then
        for _, flag in ipairs(definition.flags or {}) do
            invalid = invalid or flag == monster_flags.NO_SKELETON
        end
    end

    if not invalid then
        return id, false
    end

    -- This pinned source vault includes formicid and octopode skeleton
    -- alternatives even though both species have M_NO_SKELETON. Preserve
    -- their weighted slots but materialize a typed no-spawn outcome.
    local source_fault = site.path ==
        "vaults/arrival/dreamdust_arrival_sigmund_warning.des"

    if source_fault and skeleton then
        return id, true
    end

    choice.fail(site, name, "monster species cannot produce this corpse")
end

-- Validate source-only monster names and colour annotations before population.
function resolve.validate_monster(selected, site)
    local name = selected.name

    if selected.colour and not colours.VALID[selected.colour:lower()] then
        choice.fail(site, selected.source, "unknown monster colour " .. selected.colour)
    end

    if selected.no_spawn or random_monster_names[name] or
        name:match("^monster_array_[1-7]$") then
        return
    end

    local base_name = name:match("^(.-) zombie$") or
        name:match("^(.-) skeleton$") or
        name:match("^(.-) simulacrum$")

    if name:match(" band$") then
        base_name = name:match("^(.-) band$")
    end

    if slime_blob.size_for_name(name) then
        return
    end

    find_name(categories.MONSTERS, base_name or name, site)
end

-- Permit random-item tokens but require concrete names to resolve in the catalog.
function resolve.validate_item(selected, site)
    local name = selected.name

    if not valid_discipline(selected.disc) then
        choice.fail(site, selected.source,
            "unknown book discipline " .. selected.disc)
    end

    if selected.no_spawn or random_item_names[name] or
        name == "randbook" or name == "any randbook" or
        name:match("^item_array_[1-8]$") then
        return
    end

    local base_name = name:match("^(.-) corpse$") or
        name:match("^(.-) skeleton$")

    if base_name then
        named_corpse_species(base_name,
            name:match(" skeleton$") ~= nil, site)
    else
        find_name(categories.ITEMS, name, site)
    end
end

-- A unique already alive cannot be materialized from another vault record.
local function unique_already_exists(ctx, kind_id)
    local definition = catalog.get(categories.MONSTERS, kind_id)
    local unique = false

    for _, flag in ipairs(definition.flags or {}) do
        unique = unique or flag == "M_UNIQUE"
    end

    if not unique or not ctx.query then
        return false
    end

    for _, entity in ipairs(ctx:query({ "core.actor" })) do
        local actor = ctx:get(entity, "core.actor")

        if actor.kind_id == kind_id then
            return true
        end
    end

    return false
end

-- Resolve source monster aliases and corpse forms against the live catalog at spawn time.
-- Apply source depth and corpse special cases before returning a concrete monster ID.
function resolve.monster(ctx, selected, depth, site)
    if selected.no_spawn then
        return { no_spawn = true }
    end

    local name = selected.name
    local base_name = name:match("^(.-) zombie$") or
        name:match("^(.-) skeleton$") or
        name:match("^(.-) simulacrum$")
    local variant = name:match(" (zombie)$") or
        name:match(" (skeleton)$") or
        name:match(" (simulacrum)$")
    local blob_size = slime_blob.size_for_name(name)
    local band_name = name:match("^(.-) band$")
    local kind_id
    local base_id
    local colour = selected.colour and selected.colour:lower()

    if colour == colours.ANY then
        colour = colours.RANDOM[ctx:random("vault_colour", #colours.RANDOM) + 1]
    end

    if random_monster_names[name] then
        kind_id = random_monsters.pick(ctx, name, source_depth(selected, depth), site)
    elseif name:match("^monster_array_[1-7]$") then
        -- Source mons_list::get_monster falls back to RANDOM_MONSTER.
        kind_id = random_monsters.pick(ctx, name, source_depth(selected, depth), site)
    elseif blob_size then
        kind_id = monster_ids.MONS_SLIME_CREATURE
    elseif band_name then
        kind_id = find_name(categories.MONSTERS, band_name, site)
    elseif base_name then
        if variant == "zombie" then
            kind_id = monster_ids.MONS_ZOMBIE
        elseif variant == "skeleton" then
            kind_id = monster_ids.MONS_SKELETON
        else
            kind_id = monster_ids.MONS_SIMULACRUM
        end
        base_id = find_name(categories.MONSTERS, base_name, site)
    else
        kind_id = find_name(categories.MONSTERS, name, site)
    end

    if unique_already_exists(ctx, kind_id) then
        return { no_spawn = true }
    end

    return {
        kind_id = kind_id,
        base_id = base_id,
        blob_size = blob_size,
        band = band_name ~= nil,
        variant = variant,
        colour = colour,
        attitude = selected.attitude,
        spells = selected.spells,
        equipment = selected.equipment,
        generate_awake = selected.generate_awake or false,
    }
end

-- Random stock and named items are resolved only when population owns a live context.
function resolve.item(ctx, selected, depth, site)
    if selected.no_spawn then
        return { no_spawn = true }
    end

    local name = selected.name

    if name:match("^item_array_[1-8]$") then
        -- Source item_list::get_item returns an empty spec for an absent slot.
        return { no_spawn = true }
    end
    local base_name = name:match("^(.-) corpse$") or name:match("^(.-) skeleton$")
    local variant = name:match(" (corpse)$") or name:match(" (skeleton)$")
    local kind_id
    local base_id
    local quality = item_quality.ORDINARY
    local generation_depth = source_depth(selected, depth)
    local request

    if name == "randbook" or name == "any randbook" then
        kind_id = item_ids.BOOK_RANDART_THEME
    elseif random_item_names[name] then
        request = name
        local described = random_items.describe(name, generation_depth)

        kind_id = described.kind_id
        quality = described.quality
        generation_depth = described.depth
    elseif name == "corpse" or name == "skeleton" then
        variant = name
        kind_id = name == "corpse" and item_ids.CORPSE_BODY or item_ids.CORPSE_SKELETON
        base_id = generic_corpse_species(ctx, source_depth(selected, depth),
            name == "skeleton", site)
    elseif base_name then
        kind_id = variant == "corpse" and item_ids.CORPSE_BODY or item_ids.CORPSE_SKELETON
        local legacy_fault

        base_id, legacy_fault = named_corpse_species(base_name,
            variant == "skeleton", site)

        if legacy_fault then
            return { no_spawn = true }
        end
    else
        kind_id = find_name(categories.ITEMS, name, site)
    end

    return {
        kind_id = kind_id,
        base_id = base_id,
        variant = variant,
        quantity = selected.quantity,
        quality = quality,
        request = request,
        generation_depth = generation_depth,
        disc = selected.disc,
        numspells = selected.numspells,
        ident = selected.ident,
        tile = selected.tile,
        weapon_tile = selected.wtile,
        item_name = selected.itemname,
    }
end

return resolve
