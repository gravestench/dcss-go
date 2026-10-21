-- Example: A hook SUBST is inserted where its Lua block appears in the DES operation stream.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local hooks = require("policy.generation.vaults.hooks")
local transforms = require("policy.generation.vaults.transforms")
local catalog = require("policy.generation.vaults.catalog")
local selection = require("policy.generation.vaults.selection")
local used = require("policy.generation.vaults.used")
local entity_specs = require("policy.generation.vaults.specs.validate")

-- Walk declarations in source order. Hooks insert operations at their exact
-- source position, and non-terrain effects become typed level intent.
local operations = {}

local informational = {
    [directives.TAGS] = true,
    [directives.ORIENT] = true,
    [directives.WEIGHT] = true,
    [directives.DEPTH] = true,
    [directives.PLACE] = true,
    [directives.CHANCE] = true,
    [directives.HOOK_POST_PLACE] = true,
    [directives.HOOK_VALIDATE] = true,
}

local intent_kinds = {
    [directives.KFEAT] = effects.FEATURE,
    [directives.KMONS] = effects.MONSTER,
    [directives.KITEM] = effects.ITEM,
    [directives.MARKER] = effects.MARKER,
    [directives.COLOUR] = effects.COLOUR,
    [directives.FTILE] = effects.TILE,
    [directives.RTILE] = effects.TILE,
    [directives.TILE] = effects.TILE,
    [directives.KMASK] = effects.MASK,
    [directives.KPROP] = effects.PROPERTY,
    -- Shoals tide-height declarations are keyed cell properties. The
    -- Shoals overlay applies them after the map paints its terrain.
    [directives.FHEIGHT] = effects.PROPERTY,
    [directives.MONS] = effects.MONSTER,
    [directives.ITEM] = effects.ITEM,
}

-- Whole-level source colours and tiles have no keyed glyph. Keep their
-- instruction as typed generation data for the Temple installer and tiles UI.
local level_styles = {
    [directives.LFLOORCOL] = true,
    [directives.LROCKCOL] = true,
    [directives.LFLOORTILE] = true,
    [directives.LROCKTILE] = true,
}

-- Parse keyed target and mode before creating a typed declaration record.
local function assignment(argument)
    local target, mode, value = argument:match("^%s*(%S+)%s+([=:])%s*(.-)%s*$")

    if not target then
        target, mode, value = argument:match("^%s*([^=:]+)([=:])%s*(.-)%s*$")
    end

    if not target then
        target, mode, value = argument:match("^%s*([=:])([=:])%s*(.-)%s*$")
    end

    if target then
        return target:gsub("%s", ""), mode, value
    end
end

-- Keep keyed glyph declarations typed until their matching map cells are known.
local function declaration_record(vault, operation, argument)
    local kind = intent_kinds[operation.kind]

    if not kind then
        error(string.format("%s:%d: vault %s: unknown placement operation %s",
            vault.path, operation.line or 0, vault.id, operation.kind))
    end

    local targets, mode, identity = assignment(argument)

    if not targets then
        if operation.kind == directives.MONS or operation.kind == directives.ITEM then
            targets = ""
            identity = argument
        else
            error(string.format("%s:%d: vault %s: invalid %s declaration %s",
                vault.path, operation.line or 0, vault.id,
                operation.kind, argument))
        end
    end

    return {
        kind = kind,
        directive = operation.kind,
        targets = targets,
        identity = identity,
        assignment_mode = mode,
        line = operation.line,
        vault_id = vault.id,
    }
end

-- Split comma declarations without losing their shared source line.
local function declaration_records(vault, operation)
    if operation.kind == directives.MARKER then
        return { declaration_record(vault, operation, operation.argument) }
    end

    -- A keyed item or monster declaration owns one glyph assignment.
    -- Commas after it separate slots within that assignment, and a later
    -- weighted alternative such as `w:15` is not another glyph target.
    if operation.kind == directives.KITEM or
        operation.kind == directives.KMONS then
        return { declaration_record(vault, operation, operation.argument) }
    end

    local records = {}
    local argument = operation.argument

    -- A comma immediately before `=` can be a target glyph, as in the
    -- source Swamp KFEAT `^, = .`: both `^` and `,` become floor. It does
    -- not separate two declarations because no assignment precedes it.
    if argument:match("^%s*%S+,%s*[=:]") then
        return { declaration_record(vault, operation, argument) }
    end

    local comma_target, remainder = argument:match(
        "^(%s*,%s*[=:]%s*[^,]*)(.*)$")

    if comma_target then
        -- A leading comma can itself be a map glyph, as in KPROP: , = bloody.
        -- Consume that assignment before splitting later comma declarations.
        records[1] = declaration_record(vault, operation, comma_target)
        argument = remainder:gsub("^%s*,%s*", "")
    end

    for part in (argument .. ","):gmatch("(.-),") do
        if part ~= "" then
            local targets = assignment(part)

            if targets or #records == 0 then
                records[#records + 1] = declaration_record(vault, operation, part)
            else
                local prior = records[#records]

                prior.identity = prior.identity .. "," .. part
            end
        end
    end

    if #records == 0 then
        return { declaration_record(vault, operation, operation.argument) }
    end

    return records
end

-- A Lua hook can attach a marker to the cells present at this exact source
-- position. Later SUBST statements may erase the glyph, but the marker
-- stays bound to those cells and rotates with the finished vault.
local function anchored_markers(cells, record)
    local argument = record.arguments
    local glyph = argument and argument.glyph

    if type(glyph) ~= "string" or #glyph ~= 1 or
        type(argument.identity) ~= "string" then
        error("vault marker record needs one glyph and an identity")
    end

    local anchored = {}

    for y, row in ipairs(cells) do
        for x, source in ipairs(row) do
            if source == glyph then
                local marker = {}

                for key, value in pairs(record) do
                    marker[key] = value
                end

                marker.identity = argument.identity
                marker.targets = glyph
                marker.source = glyph
                marker.local_x = x
                marker.local_y = y
                anchored[#anchored + 1] = marker
            end
        end
    end

    return anchored
end

-- Array directives advance slot numbers in authored order across comma-separated entries.
local function array_records(vault, operation, first_slot)
    local glyphs = operation.kind == directives.MONS and "1234567" or "defghijk"
    local records = {}

    for part in (operation.argument .. ","):gmatch("(.-),") do
        local identity = part:match("^%s*(.-)%s*$")
        local index = first_slot + #records

        if identity == "" or index > #glyphs then
            error(string.format("%s:%d: vault %s: invalid %s array",
                vault.path, operation.line or 0, vault.id, operation.kind))
        end

        records[#records + 1] = {
            kind = intent_kinds[operation.kind],
            directive = operation.kind,
            targets = glyphs:sub(index, index),
            identity = identity,
            line = operation.line,
            vault_id = vault.id,
        }
    end

    return records, first_slot + #records
end

-- Parse the complete helper choice even when its source glyph is absent.
-- This rejects malformed optional declarations without spending RNG on them.
local function helper_options(argument)
    local source, choices = argument:match("^%s*(%S+)%s*:%s*(.-)%s*$")

    if not source or source == "" or not choices or choices == "" then
        error("SUBVAULT needs source glyphs and a tag choice")
    end

    local options = {}
    local total = 0

    for part in (choices .. "/"):gmatch("(.-)/") do
        local tag, weight = part:match("^%s*(%S+)%s+w:(%d+)%s*$")

        if not tag then
            -- Source SUBVAULT weights use tag:3 as well as the newer w:3
            -- form. Both choose from the same weighted helper pool.
            tag, weight = part:match("^%s*(%S+):(%d+)%s*$")
        end

        if not tag then
            tag = part:match("^%s*(%S+)%s*$")
            weight = 10
        end

        if not tag then
            error("SUBVAULT has an invalid tag choice " .. part)
        end

        total = total + tonumber(weight)
        options[#options + 1] = {
            tag = tag,
            weight = tonumber(weight),
        }
    end

    return source, options, total
end

-- Draw one source-weighted helper tag only for a glyph present in the map.
local function helper_choice(options, total, random)
    local roll = random:roll(total)

    for _, option in ipairs(options) do
        if roll < option.weight then
            return option.tag
        end

        roll = roll - option.weight
    end

    error("SUBVAULT tag choice exceeded its total weight")
end

-- A SUBVAULT tag selects a weighted map from the same effective catalog as
-- other tagged child requests. Depth and branch still constrain nested
-- helpers; file order must not silently make the first helper permanent.
local function helper_for_tag(tag, random, player, state)
    if not player or not player.branch_id then
        error("SUBVAULT requires current branch and depth")
    end

    local selected = selection.choose_tag(random, tag, {
        branch_id = player.branch_id,
        depth = player.depth,
        branch_bottom = player.branch_bottom,
        absolute_depth = player.absolute_depth,
        layout_family = player.layout_family,
        player = player,
        used = state.used,
        ignore_chance = true,
    })

    if not selected then
        error("SUBVAULT has no eligible helper tagged " .. tag)
    end

    return catalog.get(selected.id)
end

-- Convert helper rows to mutable cells before transformations and embedding.
local function helper_matrix(vault)
    local width = 0
    local cells = {}

    for _, row in ipairs(vault.rows) do
        width = math.max(width, #row)
    end

    for y, row in ipairs(vault.rows) do
        cells[y] = {}

        for x = 1, width do
            local glyph = row:sub(x, x)

            cells[y][x] = glyph == "" and " " or glyph
        end
    end

    return cells, width
end

-- Translate helper records from helper-local cells into the parent vault coordinates.
local function localize_helper_records(records, cells, low_x, low_y)
    local located = {}

    for _, record in ipairs(records) do
        local targets = record.targets or
            (record.arguments and record.arguments.glyph)
        local count = 0

        if targets and targets ~= "" then
            for y, row in ipairs(cells) do
                for x, glyph in ipairs(row) do
                    local key = x .. ":" .. y

                    if glyph ~= " " and targets:find(glyph, 1, true) and
                        not (record.excluded_cells and
                            record.excluded_cells[key]) then
                        local copy = {}

                        for key, value in pairs(record) do
                            copy[key] = value
                        end

                        copy.excluded_cells = nil
                        copy.local_x = low_x + x - 1
                        copy.local_y = low_y + y - 1
                        copy.source = glyph
                        located[#located + 1] = copy
                        count = count + 1
                    end
                end
            end
        end

        if count == 0 then
            record.local_x = low_x
            record.local_y = low_y
            record.pending = true
            record.excluded_cells = nil
            located[#located + 1] = record
        end
    end

    return located
end

-- Count helper cells that actually land on the parent's source mask. The
-- source map_def engine tries orientation and offsets against this mask;
-- a bounding-box-only fit can clip the one keyed branch gate in a wing.
local function helper_overlap(parent, cells, source, left, top)
    local count = 0

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if glyph ~= " " and source:find(
                parent[top + y - 1][left + x - 1], 1, true) then
                count = count + 1
            end
        end
    end

    return count
end

-- Fit a rotated helper anywhere inside the source glyph bounds. Keep the
-- first maximum in fixed orientation/coordinate order so file discovery
-- cannot change a seed and helper content is not clipped by a zero offset.
local function fit_helper(parent, cells, helper, source, low_x, low_y,
    region_width, region_height)
    local best
    local maximum_turns = helper.tags.no_rotate and 0 or 3

    for turns = 0, maximum_turns do
        local oriented = transforms.rotate(cells, turns)
        local width = #oriented[1]
        local height = #oriented

        if width <= region_width and height <= region_height then
            for offset_y = 0, region_height - height do
                for offset_x = 0, region_width - width do
                    local left = low_x + offset_x
                    local top = low_y + offset_y
                    local overlap = helper_overlap(parent, oriented,
                        source, left, top)

                    if not best or overlap > best.overlap then
                        best = {
                            cells = oriented,
                            left = left,
                            top = top,
                            overlap = overlap,
                        }
                    end
                end
            end
        end
    end

    return best
end

-- Resolve helper maps before glyph transformations so substitutions operate on the composed cell matrix.
local function embed_helper(cells, source, helper, random, depth, player,
    state)
    if depth > 4 then
        error("SUBVAULT recursion exceeds four levels")
    end

    local low_x, low_y, high_x, high_y

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if source:find(glyph, 1, true) then
                low_x = math.min(low_x or x, x)
                low_y = math.min(low_y or y, y)
                high_x = math.max(high_x or x, x)
                high_y = math.max(high_y or y, y)
            end
        end
    end

    if not low_x then
        error("SUBVAULT source glyph " .. source .. " is absent")
    end

    local helper_cells, helper_width = helper_matrix(helper)
    local region_width = high_x - low_x + 1
    local region_height = high_y - low_y + 1

    -- An empty source MAP delegates its exact geometry to the parent glyph
    -- region. The named hook can then paint only that local rectangle.
    if #helper_cells == 0 then
        helper_width = region_width

        for y = 1, region_height do
            helper_cells[y] = {}

            for x = 1, region_width do
                helper_cells[y][x] = " "
            end
        end
    end

    local fit = fit_helper(cells, helper_cells, helper, source,
        low_x, low_y, region_width, region_height)

    if not fit then
        error(string.format(
            "SUBVAULT helper %s is %dx%d; source region is %dx%d",
            helper.id, helper_width, #helper_cells,
            region_width, region_height))
    end

    helper_cells = fit.cells
    low_x = fit.left
    low_y = fit.top

    local nested_records = operations.apply(helper, helper_cells,
        random, depth + 1, player, state)

    -- A helper's rectangular bounds may cross another SUBVAULT region.
    -- Only cells carrying one of the source glyphs belong to this helper;
    -- masking the rest also prevents misplaced keyed effect records.
    local claimed = {}

    for y, row in ipairs(helper_cells) do
        for x, glyph in ipairs(row) do
            local parent_y = low_y + y - 1
            local parent_x = low_x + x - 1

            if source:find(cells[parent_y][parent_x], 1, true) and
                glyph ~= " " then
                cells[parent_y][parent_x] = glyph
                claimed[parent_x .. ":" .. parent_y] = true
            else
                row[x] = " "
            end
        end
    end

    local located = localize_helper_records(nested_records,
        helper_cells, low_x, low_y)

    return located, claimed
end

-- A missing helper fit is a source error rather than a silently skipped decoration.
local function apply_subvault(vault, cells, operation, random, depth,
    player, state)
    local source, options, total = helper_options(operation.argument)

    -- Some source maps declare a shared set of optional helper glyphs.
    -- Quinsquares, for example, declares C but contains only A, B, D, E.
    -- An absent glyph has no placement site and must not draw a helper.
    local present = false

    for _, row in ipairs(cells) do
        for _, glyph in ipairs(row) do
            present = present or source:find(glyph, 1, true) ~= nil
        end
    end

    if not present then
        return {}, {}
    end

    local tag = helper_choice(options, total, random)
    local helper = helper_for_tag(tag, random, player, state)
    local ok, result, claimed = pcall(embed_helper,
        cells, source, helper, random, depth, player, state)

    if not ok then
        error(string.format("%s:%d: vault %s: SUBVAULT %s: %s",
            vault.path, operation.line or 0, vault.id, helper.id, result))
    end

    -- A failed fit must never reserve a name or tag. Commit the successful
    -- helper only after its cells and nested effects have been embedded.
    state.used:add(helper)

    for selected_tag in pairs(helper.tags) do
        state.selected_tags[selected_tag] = true
    end

    return result, claimed
end

-- Expose only controlled random, context, and emission methods to ported vault hooks.
local function hook_api(random, events, line, player, cells, state,
    vault, hook_values)
    local api = {}

    player = player or {}

    -- Source-sized helpers receive a local matrix, never the parent level.
    function api:map_size()
        return cells[1] and #cells[1] or 0, #cells
    end

    -- Read the current local glyph after earlier source substitutions and
    -- hook edits. Maze scripts need to inspect their own evolving map.
    function api:cell(x, y)
        local width, height = self:map_size()

        if type(x) ~= "number" or type(y) ~= "number" or
            x % 1 ~= 0 or y % 1 ~= 0 or
            x < 0 or y < 0 or x >= width or y >= height then
            error("vault hook cell is outside its local MAP")
        end

        return cells[y + 1][x + 1]
    end

    -- Paint only a cell owned by this hook's current MAP. Coordinates are
    -- zero-based because the source DES Lua API used zero-based map points.
    function api:set_cell(x, y, glyph)
        local width, height = self:map_size()

        if type(x) ~= "number" or type(y) ~= "number" or
            x % 1 ~= 0 or y % 1 ~= 0 or
            x < 0 or y < 0 or x >= width or y >= height then
            error("vault hook cell is outside its local MAP")
        end

        if type(glyph) ~= "string" or #glyph ~= 1 then
            error("vault hook cell needs one glyph")
        end

        cells[y + 1][x + 1] = glyph
    end

    -- The current helper's source tags determine whether its rune slot is
    -- a prize or an ordinary chance, independent of its selected file name.
    function api:has_tag(tag)
        return vault.tags[tag] == true
    end

    -- A later quadrant can see successful earlier children without any
    -- process-global rune or helper registry.
    function api:has_placed_tag(tag)
        return state.selected_tags[tag] == true
    end

    -- Avoid a draw for a bound of one while exposing hook-safe layout randomness.
    function api:roll(bound)
        if bound <= 1 then
            return 0
        end

        return random:roll(bound)
    end

    -- Keep hook one-in choices on the vault layout stream.
    function api:one_in(bound)
        return random:one_in(bound)
    end

    -- Use one two-way layout draw for a hook branch.
    function api:coinflip()
        return random:one_in(2)
    end

    -- Index authored Lua lists from a bounded zero-based layout roll.
    function api:random_from(values)
        return values[random:roll(#values) + 1]
    end

    -- Expose inclusive range draws without letting hooks choose a different stream.
    function api:random_range(first, last)
        return first + random:roll(last - first + 1)
    end

    -- Certain and impossible chances must not consume a hook RNG draw.
    function api:chance(numerator, denominator)
        return numerator >= denominator or
            (numerator > 0 and self:roll(denominator) < numerator)
    end

    -- Consume one layout draw per die so scripted source order remains observable.
    function api:roll_dice(count, sides)
        local total = 0

        for _ = 1, count do
            total = total + self:roll(sides) + 1
        end

        return total
    end

    -- Select without replacement while preserving the draw sequence of the hook.
    function api:subset(values, count)
        local remaining = {}
        local selected = {}

        for index, value in ipairs(values) do
            remaining[index] = value
        end

        for _ = 1, count do
            local index = self:roll(#remaining) + 1

            selected[#selected + 1] = table.remove(remaining, index)
        end

        return selected
    end

    -- Read the placement branch captured when this hook API was built.
    function api:branch_id()
        return player.branch_id
    end

    -- A map can key a branch gate only on its scheduled parent floor.
    -- This fact comes from the saved branch schedule, not a guessed depth.
    function api:branch_entry(branch_id)
        return player.branch_entries and
            player.branch_entries[branch_id] or false
    end

    -- Read local branch depth for source branch-dependent scripts.
    function api:depth()
        return player.depth
    end

    -- Pan exit vaults scale their portal odds with the five collected Pan
    -- runes. The region generator supplies this saved player fact; requiring
    -- it avoids silently treating a missing capture as zero collected runes.
    function api:pan_rune_count()
        if type(player.pan_rune_count) ~= "number" then
            error("Pan vault hook needs saved Pan rune count")
        end

        return player.pan_rune_count
    end

    -- Pan vault scripts inspect the saved rune ledger supplied by their
    -- generator. A missing ledger is a broken call contract, never an
    -- implicit claim that the player has collected no runes.
    function api:has_rune(item_id)
        if type(player.collected_runes) ~= "table" then
            error("Pan vault hook needs saved rune progress")
        end

        return player.collected_runes[item_id] == true
    end

    -- Use absolute depth when present, otherwise the captured local depth.
    function api:absolute_depth()
        return player.absolute_depth or player.depth
    end

    -- Vault scripts need the branch's last local floor to suppress shafts
    -- that would lead beyond it. The caller supplies this with the floor.
    function api:branch_bottom()
        if type(player.branch_bottom) ~= "number" then
            error("vault hook needs the current branch bottom")
        end

        return player.branch_bottom
    end

    -- Let depth-scaled shop hooks compare local progress to branch bottom.
    function api:depth_fraction()
        return player.depth / player.branch_bottom
    end

    -- Expose the selected map tag for shop-or-temple controller decisions.
    function api:map_tag()
        return player.map_tag
    end

    -- Child maps read the controller's local choices without a process
    -- global or a family-specific engine API.
    function api:setting(name)
        return player.settings and player.settings[name]
    end

    -- Source DES scripts can calculate a value at one line and use it at a
    -- later line. Keep it local to this single map application, including
    -- failed placement attempts; no value enters the save or another map.
    function api:remember(name, value)
        if type(name) ~= "string" or name == "" then
            error("vault hook memory needs a nonempty name")
        end

        hook_values[name] = value
    end

    -- A missing earlier script site is a broken port, not a fresh RNG draw.
    function api:recall(name)
        local value = hook_values[name]

        if value == nil then
            error("vault hook memory is missing " .. tostring(name))
        end

        return value
    end

    -- Avoid offering a unique item already created in the current run.
    function api:unique_generated(name)
        return player.unique_items and player.unique_items[name] or false
    end

    -- Generation hooks can inspect durable unique claims without mutating
    -- the player or carrying a process-global set between map attempts.
    function api:unique_seen(kind_id)
        return player.unique_monsters and
            player.unique_monsters[kind_id] == true or false
    end

    -- Read a choice already persisted by the floor owner. Hook expansion
    -- must not make new run-wide decisions while a map is being retried.
    function api:run_choice(key)
        if not player.run_choices or not player.run_choices[key] then
            error("vault hook needs saved run choice " .. tostring(key))
        end

        return player.run_choices[key]
    end

    -- Build one stable owner name from layout-stream syllable choices.
    function api:random_name()
        local syllables = {
            "an", "ar", "bel", "dar", "en", "far", "gil", "is",
            "kor", "lin", "mor", "nar", "or", "ran", "sil", "vor",
        }
        local parts = {}

        for _ = 1, 3 do
            parts[#parts + 1] = self:random_from(syllables)
        end

        local name = table.concat(parts)

        return name:sub(1, 1):upper() .. name:sub(2)
    end

    -- Queue a typed effect record at this hook location for later placement.
    function api:record(kind, arguments)
        events[#events + 1] = {
            type = "record",
            value = {
                kind = kind,
                arguments = arguments,
                line = line,
            },
        }
    end

    -- Queue a DES directive at this hook location before subsequent operations.
    function api:emit(kind, argument)
        events[#events + 1] = {
            type = "directive",
            value = {
                kind = kind,
                argument = argument,
                line = line,
            },
        }
    end

    -- Read the starting species captured before the first level is generated.
    function api:player_species()
        return player.species_id
    end

    -- Use the player monster name only when the source map requests remains.
    function api:player_monster()
        return player.monster
    end

    -- Supply a stable fallback name while generating arrival grave text.
    function api:player_name()
        return player.name or "Player"
    end

    -- Distinguish validation from an actual started game in arrival scripts.
    function api:game_started()
        return player.started or false
    end

    -- Runtime hook expansion never uses the validation-only branch.
    function api:validating()
        return false
    end

    -- The operation phase has no placed marker coordinates yet.
    function api:marker_positions()
        return nil
    end

    -- Exit checks are deferred until the map has been placed and connected.
    function api:has_exit()
        return true
    end

    return api
end

-- Walk source operations in order so hook emissions and substitutions see preceding edits.
function operations.apply(vault, cells, random, depth, player, state)
    depth = depth or 0
    state = state or {
        used = used.new(player and player.prior_vault_ids),
        selected_tags = {},
    }
    local records = {}
    local nested_claims = {}
    local array_slots = {
        [directives.MONS] = 1,
        [directives.ITEM] = 1,
    }
    local hook_values = {}

    -- Validate one source operation, then apply terrain or queue its typed effect.
    local function apply_operation(operation)
        entity_specs.operation(vault, operation)

        if operation.kind == directives.HOOK_VETO then
            records[#records + 1] = {
                kind = effects.VETO,
                method = operation.argument,
                line = operation.line,
                vault_id = vault.id,
            }
        elseif operation.kind == directives.SUBVAULT then
            local nested, claimed = apply_subvault(vault, cells,
                operation, random, depth, player, state)

            -- The helper owns these cells even when a later parent hook
            -- declares a keyed monster for the same glyph. Apply the mask
            -- after all declarations, so source operation order cannot
            -- spawn both actors on one cell.
            for key in pairs(claimed) do
                nested_claims[key] = true
            end

            for _, record in ipairs(nested) do
                records[#records + 1] = record
            end
        elseif operation.kind == directives.MONS or
            operation.kind == directives.ITEM then
            local entries, next_slot = array_records(
                vault,
                operation,
                array_slots[operation.kind]
            )

            array_slots[operation.kind] = next_slot

            for _, record in ipairs(entries) do
                records[#records + 1] = record
            end
        elseif level_styles[operation.kind] then
            records[#records + 1] = {
                kind = effects.GENERATION_RULE,
                identity = "level_style",
                directive = operation.kind,
                arguments = {
                    value = operation.argument,
                },
                line = operation.line,
                vault_id = vault.id,
                pending = true,
            }
        elseif not informational[operation.kind] then
            if not transforms.apply(cells, operation, random) then
                for _, record in ipairs(declaration_records(vault, operation)) do
                    records[#records + 1] = record
                end
            end
        end
    end

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_RUN then
            local events = {}
            local api = hook_api(random, events, operation.line,
                player, cells, state, vault, hook_values)

            hooks.run(vault, operation.argument, api)

            for _, event in ipairs(events) do
                if event.type == "directive" then
                    apply_operation(event.value)
                else
                    local record = event.value

                    if record.kind == effects.MARKER and
                        record.arguments and record.arguments.glyph then
                        for _, anchored in ipairs(anchored_markers(cells, record)) do
                            records[#records + 1] = anchored
                        end
                    else
                        if transforms.apply_effect(cells, record, random) then
                            record.pending = false
                        end

                        records[#records + 1] = record
                    end
                end
            end
        else
            apply_operation(operation)
        end
    end

    for _, record in ipairs(records) do
        record.vault_id = record.vault_id or vault.id
        record.path = record.path or vault.path

        if record.vault_id == vault.id and record.targets and
            next(nested_claims) then
            record.excluded_cells = record.excluded_cells or {}

            for key in pairs(nested_claims) do
                record.excluded_cells[key] = true
            end
        end
    end

    return records, state.used:ids(), hook_values
end

return operations
