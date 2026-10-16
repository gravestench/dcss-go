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

local resolve = {}
local names_by_category = {}

local random_monster_names = {
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
}

local function active(definition)
    return definition.status ~= "removed" and
        definition.status ~= "enum_only" and
        not definition.explicitly_removed
end

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
                    local ids = index[name] or {}

                    if ids[#ids] ~= definition.id then
                        ids[#ids + 1] = definition.id
                    end

                    index[name] = ids
                end
            end
        end
    end

    names_by_category[category] = index

    return index
end

local function find_name(category, name, site)
    local ids = name_index(category)[name]

    if not ids then
        choice.fail(site, name, "unknown " .. category .. " name")
    end

    if #ids > 1 then
        choice.fail(site, name, string.format(
            "ambiguous %s name: %s and %s", category, ids[1], ids[2]))
    end

    return ids[1]
end

local function source_depth(selected, depth)
    local value = selected.place and selected.place:match("^D:(%d+)$")

    return tonumber(value) or depth
end

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
        name:match("^(.-) skeleton$")

    find_name(categories.MONSTERS, base_name or name, site)
end

function resolve.validate_item(selected, site)
    local name = selected.name

    if selected.no_spawn or random_item_names[name] or
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

function resolve.monster(ctx, selected, depth, site)
    if selected.no_spawn then
        return { no_spawn = true }
    end

    local name = selected.name
    local base_name = name:match("^(.-) zombie$") or name:match("^(.-) skeleton$")
    local variant = name:match(" (zombie)$") or name:match(" (skeleton)$")
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
    elseif base_name then
        kind_id = variant == "zombie" and monster_ids.MONS_ZOMBIE or monster_ids.MONS_SKELETON
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
        variant = variant,
        colour = colour,
        attitude = selected.attitude,
        spells = selected.spells,
        equipment = selected.equipment,
    }
end

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

    if random_item_names[name] then
        request = name
        kind_id = random_items.pick(ctx, name, generation_depth, site)

        if name == "good_item" then
            quality = item_quality.GOOD
        elseif name == "*" then
            quality = item_quality.STAR
            generation_depth = 5 + generation_depth * 2
        elseif name == "superb_item" or name == "|" then
            quality = item_quality.SUPERB
        end
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
    }
end

return resolve
