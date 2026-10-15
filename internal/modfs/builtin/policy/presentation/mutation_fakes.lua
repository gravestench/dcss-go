local catalog = require("policy.catalog")
local component = require("constants.component")
local habitats = require("constants.monster_habitats")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local size = require("constants.size")
local colors = require("policy.presentation.colors")

local fakes = {}

local function add(rows, text, color)
    rows[#rows + 1] = {
        text = text,
        color = color,
    }
end

local function species_entries(rows, species)
    for _, entry in ipairs(species.fake_mutations or {}) do
        if entry.long and entry.long ~= "" then
            add(rows, entry.long, colors.light_blue)
        end
    end
end

local function body_size_entries(ctx, owner, rows, species)
    local body_size = species.size
    local weapon_text
    local armour_text

    if body_size == size.LITTLE or body_size == size.TINY then
        armour_text = "You are too small for most types of armour."
        weapon_text = "You are very small and have problems with some larger weapons."
    elseif body_size == size.SMALL then
        weapon_text = "You are small and have problems with some larger weapons."
    elseif body_size == size.LARGE then
        armour_text = "You are too large for most types of armour."
    end

    if species.id:find("DRACONIAN", 1, true) then
        armour_text = "You cannot fit into any form of body armour."
    end

    if weapon_text and levels.effective(ctx, owner,
        mutations.MUT_NO_GRASPING) == 0 then
        add(rows, weapon_text, colors.light_blue)
    end

    if armour_text and levels.effective(ctx, owner,
        mutations.MUT_NO_ARMOUR) == 0 then
        add(rows, armour_text, colors.light_blue)
    end
end

-- Source: mutation.cc:_get_fakemuts prints species facts before real mutation
-- records. These rows describe source species capabilities already in the
-- Lua catalog, so no separate mutable state is stored for them.
function fakes.rows(ctx, owner)
    local choice = ctx:get(owner, component.PLAYER)

    if not choice then
        return {}
    end

    local species = catalog.get("species", choice.species_id)
    local rows = {}

    species_entries(rows, species)

    if species.habitat == habitats.WATER and
        levels.base(ctx, owner, mutations.MUT_MERTAIL) == 0 then
        add(rows, "You are amphibious.", colors.light_blue)
    end

    body_size_entries(ctx, owner, rows, species)

    return rows
end

return fakes
