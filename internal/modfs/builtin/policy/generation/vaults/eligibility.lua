-- Source depth and tag selectors share the same layout, species, and map
-- use checks. Keeping them here prevents a new vault stage from quietly
-- admitting maps that another stage rejects.
local categories = require("constants.catalog")
local depth = require("policy.generation.vaults.depth")

local eligibility = {}

-- layout_* tags whitelist a family; nolayout_* tags veto one. The
-- generated floor supplies its selected layout type, never a file name.
function eligibility.layout(definition, family)
    if not family then
        return true
    end

    local restricted = false
    local accepted = false

    for tag in pairs(definition.tags) do
        local requested = tag:match("^layout_(.+)$")

        if requested then
            restricted = true
            accepted = accepted or requested == family
        end
    end

    return not definition.tags["nolayout_" .. family] and
        (not restricted or accepted)
end

-- Source no_species_* tags use the species' two-letter abbreviation.
-- A generation caller without a character species cannot apply that veto.
function eligibility.species(definition, species_id)
    if not species_id then
        return true
    end

    local species = register.get(categories.SPECIES, species_id)
    local tag = "no_species_" .. species.short_name:lower()

    return not definition.tags[tag]
end

-- Check facts common to depth and explicit-tag selection before either
-- selector consumes a random draw or attempts geometry.
local function common(definition, context)
    return (not context.excluded or
            not context.excluded[definition.id]) and
        (not context.used or context.used:allows(definition)) and
        eligibility.layout(definition, context.layout_family) and
        eligibility.species(definition,
            context.player and context.player.species_id)
end

-- Random depth selection requires an authored DEPTH. A helper without one
-- remains available by its tag but cannot become an unrelated Dungeon map.
function eligibility.depth(definition, context)
    if #definition.depths == 0 or
        not depth.eligible(definition, context.branch_id,
            context.depth, context.branch_bottom,
            context.absolute_depth) or
        not common(definition, context) then
        return false
    end

    if definition.tags.unrand or definition.tags.place_unique or
        definition.tags.tutorial then
        return false
    end

    for tag in pairs(definition.tags) do
        if tag:sub(-5) == "entry" then
            return false
        end
    end

    return true
end

-- An explicit tag may select a helper with no DEPTH. When a rule exists,
-- however, the tag still respects its branch and depth limits.
function eligibility.tag(definition, context)
    return common(definition, context) and
        (#definition.depths == 0 or
            depth.eligible(definition, context.branch_id,
                context.depth, context.branch_bottom,
                context.absolute_depth))
end

return eligibility
