-- Example: A mutation that raises maximum MP triggers refresh_mp to update current capacity.
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local component = require("constants.component")

local resources = {}

-- Derived maximum MP is shared by level gains, mutation changes, and
-- equipment changes. Current MP stays put unless the new cap is lower.
-- Recalculate the MP ceiling after skills or mutations change, preserving current MP unless above the new cap.
function resources.refresh_mp(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local progress = ctx:get(player, component.PROGRESSION)
    local skills = ctx:get(player, component.SKILLS)
    local magic = ctx:get(player, component.MAGIC)

    if not identity or not progress or not skills or not magic then
        error("live MP change requires player resource state")
    end

    local species = catalog.get("species", identity.species_id)
    local maximum = formulas.max_mp(ctx, player, progress.level,
        species, skills.entries)

    magic.max = maximum
    magic.current = math.min(magic.current, maximum)
    ctx:set(player, component.MAGIC, magic)
end

return resources
