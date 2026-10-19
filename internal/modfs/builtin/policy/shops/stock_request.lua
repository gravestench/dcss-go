local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local quality = require("constants.vault_item_quality")
local resolve = require("policy.generation.vaults.specs.resolve")
local schools = require("constants.spell_schools")
local sets = require("constants.item_sets")
local skills = require("ids.skills")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local stock_request = {}

local generic_classes = {
    ["any"] = classes.OBJ_RANDOM,
    ["any weapon"] = classes.OBJ_WEAPONS,
    ["any armour"] = classes.OBJ_ARMOUR,
    ["any ring"] = classes.OBJ_JEWELLERY,
    ["any amulet"] = classes.OBJ_JEWELLERY,
    ["any jewellery"] = classes.OBJ_JEWELLERY,
    ["any wand"] = classes.OBJ_WANDS,
    ["any misc"] = classes.OBJ_MISCELLANY,
}

local set_classes = {
    ["any beam wand"] = {
        class_id = classes.OBJ_WANDS,
        set_id = sets.BEAM_WANDS,
    },
    ["any blast wand"] = {
        class_id = classes.OBJ_WANDS,
        set_id = sets.BLAST_WANDS,
    },
    ["any concealment scroll"] = {
        class_id = classes.OBJ_SCROLLS,
        set_id = sets.CONCEALMENT_SCROLLS,
    },
}

-- Report the exact DES file, line, and vault ID when stock syntax cannot be
-- mapped to a supported item request; silent fallback would change content.
local function unsupported(selected, site)
    error(string.format("%s:%d: vault %s: unsupported shop stock %s",
        site.path, site.line or 0, site.vault_id,
        selected.source))
end

-- A manual request needs a trainable skill before item generation can materialize it.
local function manual_skill(name, site)
    local key = "SK_" .. name:upper():gsub("&", ""):gsub("[^%w]+", "_")
    local id = skills[key]

    if id then
        return id
    end

    error(string.format("%s:%d: vault %s: unknown manual skill %s",
        site.path, site.line or 0, site.vault_id, name))
end

-- DES stock accepts the displayed name, an apostrophe-free form, or the unrand ID suffix.
local function unique_artefact(name)
    local normalized = name:lower():gsub("[^%w]+", "_")

    for _, definition in ipairs(catalog.all(categories.ARTEFACTS)) do
        local by_name = definition.name:lower():gsub("[^%w]+", "_")
        local no_apostrophe = definition.name:lower():gsub("'", "")
        local by_unpunctuated_name = no_apostrophe:gsub("[^%w]+", "_")
        local by_id = definition.id:lower():gsub("^unrand_", "")

        if normalized == by_name or
            normalized == by_unpunctuated_name or
            normalized == by_id or
            normalized == definition.tile_equipment then
            return definition
        end
    end

    return nil
end

-- Generated stock requests exclude unsupported item types and unavailable artefacts.
-- Example: stock_request.apply(ctx, request, selected, site) resolves a vault SHOP directive.
function stock_request.apply(ctx, request, selected, site)
    if selected.no_spawn then
        request.no_spawn = true

        return request
    end

    local generic = generic_classes[selected.name]
    local set = set_classes[selected.name]

    if set then
        request.class_id = set.class_id
        request.set_id = set.set_id
    elseif generic then
        if generic ~= classes.OBJ_RANDOM then
            request.class_id = generic
        end

        if selected.name == "any ring" then
            request.amulet = false
        elseif selected.name == "any amulet" then
            request.amulet = true
        end
    elseif selected.name == "randbook" or
        selected.name == "any randbook" or
        selected.name == "any fixed theme book" then
        request.kind_id = item_ids.BOOK_RANDART_THEME
    elseif selected.name == "any fixed level book" then
        request.kind_id = item_ids.BOOK_RANDART_LEVEL
    elseif selected.name == "any manual" then
        request.kind_id = item_ids.BOOK_MANUAL
    elseif selected.name:match("^manual of ") then
        request.kind_id = item_ids.BOOK_MANUAL
        request.manual_skill_id = manual_skill(
            selected.name:sub(#"manual of " + 1), site)
    else
        local artefact = unique_artefact(selected.name)

        if artefact then
            request.kind_id = artefact.kind_id
            request.unique_id = artefact.id
        else
            local resolved = resolve.item(ctx, selected, request.depth, site)

            request.kind_id = resolved.kind_id
            request.depth = resolved.generation_depth
        end
    end

    if selected.disc then
        local valid = false

        for _, school in pairs(schools) do
            valid = valid or school == selected.disc
        end

        if not valid then
            unsupported(selected, site)
        end
    end

    request.quantity = selected.quantity
    request.ego = selected.ego
    request.plus = selected.plus
    request.charges = selected.charges
    request.mundane = selected.mundane
    request.damaged = selected.damaged
    request.disc = selected.disc
    request.numspells = selected.numspells

    if selected.randart then
        request.quality = quality.RANDART
    elseif selected.good_item then
        request.quality = quality.GOOD
    end

    return request
end

return stock_request
