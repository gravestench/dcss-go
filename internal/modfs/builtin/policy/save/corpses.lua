local catalog = require("policy.catalog")
local roster = require("policy.population.roster")

local function flag(definition, wanted)
    for _, id in ipairs(definition.flags or {}) do
        if id == wanted then
            return true
        end
    end

    return false
end

register.policy({
    id = "save.validate_corpses",
    run = function(ctx, input)
        local allowed = roster.allowed(input.scenario_id)

        if input.scenario_id == "generated-dungeon-basic-v1" then
            allowed.MONS_GOBLIN = true
            allowed.MONS_KOBOLD = true
        end

        for _, entity in ipairs(ctx:query({ "core.corpse" })) do
            local corpse = ctx:get(entity, "core.corpse")
            local item = ctx:get(entity, "core.item")
            local position = ctx:get(entity, "core.position")

            if not item or not position or ctx:has(entity, "core.carried_by") or
                ctx:has(entity, "core.equipped") or item.quantity ~= 1 or
                corpse.freshness < 1 or corpse.freshness > 110 or
                corpse.appearance < 1 or corpse.appearance > 255 then
                error("item " .. ctx:id(entity) .. " has invalid ordinary monster corpse state")
            end

            if not allowed[corpse.monster_id] then
                error("fixed Dungeon save has unsupported corpse " .. corpse.monster_id)
            end

            local profile = roster.profile(corpse.monster_id)
            local definition = catalog.get("monsters", corpse.monster_id)

            if definition.average_hp_10x ~= profile.average or not definition.leaves_corpse then
                error("item " .. ctx:id(entity) .. " has impossible " .. corpse.monster_id .. " corpse")
            end

            if item.kind_id == "CORPSE_SKELETON" and flag(definition, "M_NO_SKELETON") then
                error("item " .. ctx:id(entity) .. " has impossible " .. corpse.monster_id .. " skeleton")
            end
        end

        return {}
    end,
})
