-- Example: An authored monster name ignores a removed catalog entry during resolution.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local choice = require("policy.generation.vaults.specs.choice")
local random_monsters = require("policy.generation.vaults.specs.random_monsters")
local random_items = require("policy.generation.vaults.specs.random_items")
local pool = require("policy.population.pool")
local generic_late_zombie = require("policy.population.generic_late_zombie")
local monster_ids = require("ids.monsters")
local branch_ids = require("ids.branches")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local weapon_brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")
local missile_brands = require("constants.missile_brands")
local item_quality = require("constants.vault_item_quality")
local manual_skill = require("policy.item_generation.manual_skill")
local colours = require("constants.vault_colours")
local monster_flags = require("constants.monster_flags")
local schools = require("constants.spell_schools")
local slime_blob = require("policy.monsters.slime_blob")
local hydra_heads = require("policy.monsters.hydra_heads")
local monster_requests = require("constants.vault_monster_requests")
local item_requests = require("constants.vault_item_requests")
local streams = require("constants.rng_streams")
local population_sentinels = require("constants.population_sentinels")

local resolve = {}
local names_by_category = {}

local random_monster_names = {
    [monster_requests.ANY_DEMON] = true,
    [monster_requests.COMMON_DEMON] = true,
    [monster_requests.GREATER_DEMON] = true,
    [monster_requests.ANY_COMMON_DEMON] = true,
    [monster_requests.RANDOM] = true,
    ["0"] = true,
    ["8"] = true,
    ["9"] = true,
    random_monster = true,
    super_out_of_depth_monster = true,
    moderate_out_of_depth_monster = true,
    [monster_requests.BASE_DRACONIAN] = true,
    [monster_requests.NONBASE_DRACONIAN] = true,
}

local random_undead_names = {
    [monster_requests.RANDOM_SPECTRE] = true,
    [monster_requests.RANDOM_SPECTRAL] = true,
    [monster_requests.RANDOM_SIMULACRUM] = true,
    [monster_requests.RANDOM_ZOMBIE] = true,
    [monster_requests.RANDOM_SKELETON] = true,
}

-- DCSS shares one late-game corpse roster across these branches. Their
-- ambient inhabitants are not the source of random zombie bodies.
local late_zombie_branches = {
    [branch_ids.BRANCH_VESTIBULE] = true,
    [branch_ids.BRANCH_DIS] = true,
    [branch_ids.BRANCH_GEHENNA] = true,
    [branch_ids.BRANCH_COCYTUS] = true,
    [branch_ids.BRANCH_TARTARUS] = true,
    [branch_ids.BRANCH_CRYPT] = true,
    [branch_ids.BRANCH_TOMB] = true,
    [branch_ids.BRANCH_ABYSS] = true,
    [branch_ids.BRANCH_PANDEMONIUM] = true,
}

local random_item_names = {
    [item_requests.ANY_WEAPON] = true,
    [item_requests.ANY_ARMOUR] = true,
    [item_requests.ANY_AMULET] = true,
    [item_requests.ANY_RING] = true,
    [item_requests.ANY_JEWELLERY] = true,
    [item_requests.ANY_MAGICAL_STAFF] = true,
    [item_requests.ANY_BOOK] = true,
    [item_requests.ANY_SCROLL] = true,
    [item_requests.ANY_CONCEALMENT_SCROLL] = true,
    [item_requests.ANY_POTION] = true,
    [item_requests.ANY_WAND] = true,
    [item_requests.ANY_MISC] = true,
    [item_requests.ANY_GOOD_ITEM] = true,
    ["any"] = true,
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
            -- Source names often include an article that the stable monster
            -- ID omits (for example, "the Serpent of Hell"). Remove it only
            -- for this exact-form check; the display-name lookup above still
            -- decides which catalog entries are candidates.
            local id_name = name:gsub("^[Tt]he%s+", "")
            local canonical = "MONS_" .. id_name:upper():gsub(
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

-- Source mons_list accepts a colour before a nonbase draconian role. Both
-- names must resolve so the role and its per-actor colour survive placement.
local function draconian_names(name)
    local colour, role = name:match("^([a-z]+) (draconian .+)$")

    if colour then
        return colour .. " draconian", role
    end
end

-- mapdef.cc treats the leading colour of an ugly thing as an actor
-- property, not part of its species name. Require a known source colour
-- and one of the two catalog species before accepting that shorthand.
local function ugly_names(name)
    local colour, species = name:match("^([a-z]+) (.+ ugly thing)$")

    if (species == "ugly thing" or species == "very ugly thing") and
        colours.VALID[colour] then
        return colour, species
    end
end

-- DES names some unrand artefacts by their source tile token rather than
-- their displayed title. Resolve those tokens through the same catalog
-- used by item generation, so no room owns a private artefact name table.
local function named_artefact(name)
    for _, definition in ipairs(catalog.all(categories.ARTEFACTS)) do
        if active(definition) and
            (definition.tile_equipment == name or
                definition.name:lower() == name:lower() or
                definition.name:lower():gsub("[^a-z0-9]+", "_") == name) then
            return definition
        end
    end
end

-- A DES D:N place overrides the current floor for this resolver request.
local function source_depth(selected, depth)
    local value = selected.place and selected.place:match("^D:(%d+)$")

    return tonumber(value) or depth
end

-- A bare source spectre or simulacrum chooses its corpse species from the
-- requested branch floor. Resolve the abbreviation through the catalog so
-- added branches use the same rule without a new hard-coded branch case.
local function undead_place(selected, depth, site)
    local abbreviation, floor =
        (selected.place or ""):match("^([A-Za-z]+):(%d+)$")

    if abbreviation then
        for _, id in ipairs(register.ids(categories.BRANCHES)) do
            local branch = register.get(categories.BRANCHES, id)

            if branch.abbreviation == abbreviation then
                return id, tonumber(floor)
            end
        end

        choice.fail(site, selected.place,
            "unknown undead source branch " .. abbreviation)
    end

    return site.branch_id or branch_ids.BRANCH_DUNGEON,
        site.local_depth or depth
end

-- Source mon-place.cc asks other branches when the current branch offers
-- no zombifiable base. It keeps the strongest rarity for a species seen
-- in multiple branches, then draws once from that combined pool. This is
-- important in Hell: the Vestibule's ambient demons leave no usable body.
local function keep_undead_species(row, by_species, ordered)
    if row.id == population_sentinels.NO_MONSTER then
        return
    end

    local monster = catalog.get(categories.MONSTERS, row.id)

    if not monster.leaves_corpse then
        return
    end

    local known = by_species[row.id]

    if known then
        known.weight = math.max(known.weight, row.weight)

        return
    end

    known = {
        id = row.id,
        weight = row.weight,
    }
    by_species[row.id] = known
    ordered[#ordered + 1] = known
end

-- Numeric source branch order keeps the fallback's first-seen species
-- order independent of file paths and alphabetical branch names.
local function source_branch_order(left, right)
    return left.numeric_id < right.numeric_id
end

-- Translate source absolute depth into each branch's local population depth.
-- A branch beyond its OOD cap contributes nothing to the fallback draw.
local function undead_all_branches(source_branch_id, source_depth)
    local source_branch = catalog.get(categories.BRANCHES, source_branch_id)
    local absolute_depth = source_depth

    if source_branch_id ~= branch_ids.BRANCH_DUNGEON then
        absolute_depth = source_branch.absolute_depth + source_depth - 1
    end

    local branches = catalog.all(categories.BRANCHES)
    local by_species = {}
    local ordered = {}

    table.sort(branches, source_branch_order)

    for _, branch in ipairs(branches) do
        local first_depth = branch.absolute_depth - 1

        if branch.id == branch_ids.BRANCH_DUNGEON then
            first_depth = 0
        end

        local local_depth = absolute_depth - first_depth
        local maximum = branch.ood_cap or branch.depth

        if local_depth >= 1 and local_depth <= maximum then
            local rows = pool.at_depth(branch.id, local_depth)

            for _, row in ipairs(rows) do
                keep_undead_species(row, by_species, ordered)
            end
        end
    end

    return ordered
end

-- Source mon-place.cc raises zombie selection depth by one plus rounded
-- absolute depth / 5. The named stream makes that rounding replayable.
local function undead_selection_depth(ctx, branch_id, floor)
    local branch = catalog.get(categories.BRANCHES, branch_id)
    local absolute_depth = floor

    if branch_id ~= branch_ids.BRANCH_DUNGEON then
        absolute_depth = branch.absolute_depth + floor - 1
    end

    local quotient = math.floor(absolute_depth / 5)
    local remainder = absolute_depth % 5
    local rounded = quotient

    if remainder > 0 and ctx:random("population", 5) < remainder then
        rounded = rounded + 1
    end

    local maximum = late_zombie_branches[branch_id] and 15 or
        (branch.ood_cap or branch.depth)

    return math.max(1, math.min(floor + 1 + rounded, maximum))
end

-- Filter the source zombie roster to species that can supply the requested
-- body. Late-game branches share the pinned generic pool instead of their
-- ambient monster pool; only a failed local draw falls back to all branches.
local function random_undead_base(ctx, selected, depth, site)
    local branch_id, floor = undead_place(selected, depth, site)
    local adjusted = undead_selection_depth(ctx, branch_id, floor)
    local rows

    if late_zombie_branches[branch_id] then
        rows = pool.at_rows(generic_late_zombie, adjusted)
    else
        rows = pool.at_depth(branch_id, adjusted)
    end
    local eligible = {}
    local total = 0

    for _, row in ipairs(rows) do
        if row.id ~= population_sentinels.NO_MONSTER then
            local definition = catalog.get(categories.MONSTERS, row.id)

            if definition.leaves_corpse then
                eligible[#eligible + 1] = row
                total = total + row.weight
            end
        end
    end

    if total == 0 then
        eligible = undead_all_branches(branch_id, adjusted)

        for _, row in ipairs(eligible) do
            total = total + row.weight
        end
    end

    if total == 0 then
        choice.fail(site, selected.source,
            "no zombifiable species in any branch")
    end

    return pool.pick(ctx, eligible, total)
end

-- Random corpse requests filter to species capable of leaving the requested remains.
local function generic_corpse_species(ctx, depth, skeleton, site)
    local rows = pool.at_depth(branch_ids.BRANCH_DUNGEON, depth)
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
        random_undead_names[name] or
        name:match("^monster_array_[1-7]$") then
        return
    end

    -- A suffix is a derived form only when the full name is absent from
    -- the catalog. Silent spectre is a species, not a spectre of "silent".
    local literal = name_index(categories.MONSTERS)[name:lower()]
    local spectral_base = name:match("^spectral (.+)$")
    local base_name

    if not literal then
        base_name = name:match("^(.-) zombie$") or
            name:match("^(.-) skeleton$") or
            name:match("^(.-) simulacrum$") or
            name:match("^(.-) spectre$")
    end

    -- Source vaults can request a spectral form of an ordinary species.
    -- Keep literal catalog monsters such as spectral thing as themselves.
    if not literal and not base_name and spectral_base and
        name_index(categories.MONSTERS)[spectral_base:lower()] then
        base_name = spectral_base
    end

    if name:match(" band$") then
        base_name = name:match("^(.-) band$")

        -- Source Vaults rooms use "0 band" for a depth-selected monster
        -- with its ordinary band, not for a species literally named 0.
        if random_monster_names[base_name] then
            return
        end
    end

    if slime_blob.size_for_name(name) then
        return
    end

    -- mapdef.cc accepts any known base monster followed by this source
    -- suffix and creates a permanent, shaped pillar of salt. The base is
    -- catalog data, not a second pillar species name.
    local salt_base = name:match("^(.-)%-shaped pillar of salt$")

    if salt_base then
        find_name(categories.MONSTERS, salt_base, site)

        return
    end

    if name == monster_requests.ANY_BASE_DRACONIAN then
        return
    end

    local fixed_draconian = name:match(
        "^any nonbase ([a-z]+) draconian$")

    if fixed_draconian then
        find_name(categories.MONSTERS,
            fixed_draconian .. " draconian", site)

        return
    end

    local ugly_colour, ugly_species = ugly_names(name)

    if ugly_colour then
        find_name(categories.MONSTERS, ugly_species, site)

        return
    end

    local source_name = base_name or name
    local draconian_base, draconian_role = draconian_names(source_name)

    if hydra_heads.from_name(source_name) then
        source_name = "hydra"
    elseif draconian_role then
        find_name(categories.MONSTERS, draconian_base, site)
        source_name = draconian_role
    end

    find_name(categories.MONSTERS, source_name, site)
end

-- Permit random-item tokens but require concrete names to resolve in the catalog.
function resolve.validate_item(selected, site)
    local name = selected.name

    if not valid_discipline(selected.disc) then
        choice.fail(site, selected.source,
            "unknown book discipline " .. selected.disc)
    end

    if not valid_discipline(selected.disc2) then
        choice.fail(site, selected.source,
            "unknown second book discipline " .. selected.disc2)
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
    elseif name:match("^manual of ") then
        manual_skill.from_name(
            name:sub(#"manual of " + 1), site)
        return
    elseif named_artefact(name) then
        return
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
    local literal = name_index(categories.MONSTERS)[name:lower()]
    local spectral_base = name:match("^spectral (.+)$")
    local base_name
    local variant

    if not literal then
        base_name = name:match("^(.-) zombie$") or
            name:match("^(.-) skeleton$") or
            name:match("^(.-) simulacrum$") or
            name:match("^(.-) spectre$")
        variant = name:match(" (zombie)$") or
            name:match(" (skeleton)$") or
            name:match(" (simulacrum)$") or
            name:match(" (spectre)$")
    end

    -- DCSS accepts both "spectral goblin" and "goblin spectre" for the
    -- same derived monster; downstream identity uses one variant name.
    if variant == "spectre" then
        variant = "spectral"
    end

    -- A named spectral form uses the generic spectral monster's behavior
    -- while retaining its base species for rendering and future corpse rules.
    if not literal and not base_name and spectral_base and
        name_index(categories.MONSTERS)[spectral_base:lower()] then
        base_name = spectral_base
        variant = "spectral"
    end
    local blob_size = slime_blob.size_for_name(name)
    local head_count = hydra_heads.from_name(base_name or name)
    local draconian_base, draconian_role = draconian_names(name)
    local band_name = name:match("^(.-) band$")
    local salt_base = name:match("^(.-)%-shaped pillar of salt$")
    local ugly_colour, ugly_species = ugly_names(name)
    local fixed_draconian = name:match(
        "^any nonbase ([a-z]+) draconian$")
    local kind_id
    local base_id
    local colour = selected.colour and selected.colour:lower() or
        ugly_colour

    if colour == colours.ANY then
        colour = colours.RANDOM[ctx:random("vault_colour", #colours.RANDOM) + 1]
    end

    if random_undead_names[name] then
        if name == monster_requests.RANDOM_ZOMBIE then
            variant = "zombie"
            kind_id = monster_ids.MONS_ZOMBIE
        elseif name == monster_requests.RANDOM_SKELETON then
            variant = "skeleton"
            kind_id = monster_ids.MONS_SKELETON
        elseif name == monster_requests.RANDOM_SIMULACRUM then
            variant = "simulacrum"
            kind_id = monster_ids.MONS_SIMULACRUM
        else
            variant = "spectral"
            kind_id = monster_ids.MONS_SPECTRAL_THING
        end

        base_id = random_undead_base(ctx, selected, depth, site)
    elseif name == monster_requests.ANY_BASE_DRACONIAN then
        kind_id = random_monsters.pick(ctx,
            monster_requests.BASE_DRACONIAN, depth, site)
    elseif fixed_draconian then
        kind_id = random_monsters.pick(ctx,
            monster_requests.NONBASE_DRACONIAN, depth, site)
        base_id = find_name(categories.MONSTERS,
            fixed_draconian .. " draconian", site)
    elseif random_monster_names[name] then
        kind_id = random_monsters.pick(ctx, name,
            source_depth(selected, depth), site, selected.place)
    elseif name:match("^monster_array_[1-7]$") then
        -- Source mons_list::get_monster falls back to RANDOM_MONSTER.
        kind_id = random_monsters.pick(ctx, name,
            source_depth(selected, depth), site, selected.place)
    elseif blob_size then
        kind_id = monster_ids.MONS_SLIME_CREATURE
    elseif band_name then
        if random_monster_names[band_name] then
            kind_id = random_monsters.pick(ctx, band_name,
                source_depth(selected, depth), site, selected.place)
        else
            kind_id = find_name(categories.MONSTERS, band_name, site)
        end
    elseif base_name then
        if variant == "zombie" then
            kind_id = monster_ids.MONS_ZOMBIE
        elseif variant == "skeleton" then
            kind_id = monster_ids.MONS_SKELETON
        elseif variant == "simulacrum" then
            kind_id = monster_ids.MONS_SIMULACRUM
        else
            kind_id = monster_ids.MONS_SPECTRAL_THING
        end
        base_id = find_name(categories.MONSTERS,
            head_count and "hydra" or base_name, site)
    elseif head_count then
        kind_id = monster_ids.MONS_HYDRA
    elseif salt_base then
        kind_id = monster_ids.MONS_PILLAR_OF_SALT
        base_id = find_name(categories.MONSTERS, salt_base, site)
    elseif ugly_species then
        kind_id = find_name(categories.MONSTERS, ugly_species, site)
    elseif draconian_role then
        kind_id = find_name(categories.MONSTERS, draconian_role, site)
        base_id = find_name(categories.MONSTERS, draconian_base, site)
    else
        kind_id = find_name(categories.MONSTERS, name, site)
    end

    -- Source branch pools can deliberately spend a vault monster draw on
    -- no creature. Keep that result as a typed empty placement instead of
    -- looking up the sentinel as a real species in the monster catalog.
    if kind_id == population_sentinels.NO_MONSTER then
        return { no_spawn = true }
    end

    if unique_already_exists(ctx, kind_id) then
        return { no_spawn = true }
    end

    local selected_spells

    if selected.spells then
        local index = 1

        if #selected.spells > 1 then
            index = ctx:random(streams.PLACEMENT, #selected.spells) + 1
        end

        selected_spells = { selected.spells[index] }
    end

    return {
        kind_id = kind_id,
        base_id = base_id,
        blob_size = blob_size,
        hydra_heads = head_count,
        band = band_name ~= nil,
        variant = variant,
        colour = colour,
        attitude = selected.attitude,
        god_id = selected.god_id,
        spells = selected_spells,
        equipment = selected.equipment,
        generate_awake = selected.generate_awake or false,
        patrolling = selected.patrolling or false,
        database_name = selected.database_name,
        custom_name = selected.custom_name or (salt_base and name),
        name_adjective = selected.name_adjective or false,
        tile = selected.tile,
        hp = selected.hp,
        hd = selected.hd,
        permanent_enchantments = selected.permanent_enchantments,
    }
end

-- A source ego token belongs to the selected item's class. Resolve it once
-- before saving the vault record so later materialization cannot reinterpret
-- a renamed modifier or silently discard an authored brand.
local function item_ego(selected, kind_id, class_id, site)
    if not selected.ego then
        return nil
    end

    -- An explicit source ego:none must suppress normal generation's brand
    -- roll. Lua's empty string is truthy, so it survives the request path.
    if selected.ego == "none" then
        return ""
    end

    local class = class_id or catalog.get(categories.ITEMS, kind_id).class
    local choices

    if class == object_classes.OBJ_WEAPONS then
        choices = weapon_brands
    elseif class == object_classes.OBJ_ARMOUR then
        choices = armour_egos
    elseif class == object_classes.OBJ_MISSILES then
        choices = missile_brands
    end

    local ego = choices and choices[selected.ego:upper()]

    if not ego then
        choice.fail(site, selected.source,
            "unknown item ego " .. selected.ego)
    end

    return ego
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
    local class_id
    local base_id
    local unique_id
    -- Source good_item is an item modifier, not part of the random item's
    -- name. Preserve it before the later live item-generation draw.
    local quality = selected.quality or
        (selected.good_item and item_quality.GOOD) or
        item_quality.ORDINARY
    local generation_depth = selected.level or source_depth(selected, depth)
    local manual_skill_id
    local request
    local mimic = selected.mimic

    if name == "randbook" or name == "any randbook" then
        kind_id = item_ids.BOOK_RANDART_THEME
    elseif name:match("^manual of ") then
        kind_id = item_ids.BOOK_MANUAL
        manual_skill_id = manual_skill.from_name(
            name:sub(#"manual of " + 1), site)
    elseif random_item_names[name] then
        request = name
        local described = random_items.describe(name, generation_depth)

        kind_id = described.kind_id
        class_id = described.class_id
        quality = selected.quality or
            (selected.good_item and item_quality.GOOD) or
            described.quality
        generation_depth = selected.level or described.depth
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
    elseif named_artefact(name) then
        local artefact = named_artefact(name)

        kind_id = artefact.kind_id
        class_id = artefact.class
        unique_id = artefact.id
    else
        kind_id = find_name(categories.ITEMS, name, site)
    end

    -- C++ first chooses the concrete item type, then rolls mimic chance.
    -- Preserve that ordering so a random book does not consume its mimic
    -- draw before its subtype and appearance are known.
    if type(mimic) == "number" then
        mimic = ctx:random(streams.PLACEMENT, mimic) == 0
    end

    return {
        kind_id = kind_id,
        unique_id = unique_id,
        class_id = class_id,
        base_id = base_id,
        variant = variant,
        quantity = selected.quantity,
        quality = quality,
        request = request,
        generation_depth = generation_depth,
        disc = selected.disc,
        disc2 = selected.disc2,
        manual_skill_id = manual_skill_id,
        numspells = selected.numspells,
        slevels = selected.slevels,
        spells = selected.spells,
        owner = selected.owner and selected.owner:gsub("_", " "),
        title = selected.title and selected.title:gsub("_", " "),
        plus = selected.plus,
        ego = item_ego(selected, kind_id, class_id, site),
        allow_uniques = selected.plus == nil and selected.ego == nil,
        ident = selected.ident,
        tile = selected.tile,
        weapon_tile = selected.wtile,
        item_name = selected.itemname,
        no_pickup = selected.no_pickup,
        mimic = mimic,
    }
end

return resolve
