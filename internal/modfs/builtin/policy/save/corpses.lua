local catalog = require("policy.catalog")
local roster = require("policy.population.roster")
local component = require("constants.component")
local doom_howl = require("policy.combat.monster_doom_howl.ids")
local branches = require("ids.branches")
local beogh_corpse = require("policy.abilities.beogh.corpse")
local draconian_base = require("policy.monsters.draconian_base")

-- Corpse validation reads source monster flags without requiring every record to list them.
local function flag(definition, wanted)
    for _, id in ipairs(definition.flags or {}) do
        if id == wanted then
            return true
        end
    end

    return false
end

local module = {}

-- Corpse roster membership belongs to the floor where the corpse lies.
-- Later branches admit jobs absent from Dungeon, including Zot draconians.
local function floor_rosters(input)
    local branches_by_level = {}

    for _, level in ipairs(input.levels) do
        branches_by_level[level.id] = level.branch_id
    end

    return branches_by_level
end

-- Corpse entities keep their decay and source-monster fields consistent across restore.
-- Example: module.run(ctx, { scenario_id = "generated-dungeon-basic-v1" }) validates corpse freshness.
function module.run(ctx, input)
    local branches_by_level = floor_rosters(input)
    local allowed_by_branch = {}

    for _, entity in ipairs(ctx:query({ "core.corpse" })) do
        local corpse = ctx:get(entity, "core.corpse")
        local item = ctx:get(entity, "core.item")
        local position = ctx:get(entity, "core.position")
        local origin = ctx:get(entity, component.VAULT_ORIGIN)
        local arrival = ctx:get(entity, doom_howl.ARRIVAL)
        local original_id = corpse.original_monster_id ~= "" and
            corpse.original_monster_id or corpse.monster_id
        -- Population rows list actor classes. Corpses may list a colored
        -- draconian or shifter variant, so keep spawn lineage separately.
        local source_id = corpse.source_monster_id ~= "" and
            corpse.source_monster_id or original_id

        if not item or not position or ctx:has(entity, "core.carried_by") or
            ctx:has(entity, "core.equipped") or item.quantity ~= 1 or
            corpse.freshness < 1 or corpse.freshness > 110 or
            corpse.appearance < 1 or corpse.appearance > 255 then
            error("item " .. ctx:id(entity) .. " has invalid ordinary monster corpse state")
        end

        if arrival and (not doom_howl.beast(corpse.monster_id) or
            arrival.created_aut < 0 or
            arrival.created_aut > input.current_aut) then
            error("item " .. ctx:id(entity) ..
                " has invalid Doom Howl corpse origin")
        end

        local branch_id = branches_by_level[position.level_id]

        if not branch_id then
            error("corpse has no saved floor " .. ctx:id(entity))
        end

        local allowed = allowed_by_branch[branch_id]

        if not allowed then
            allowed = roster.allowed(input.scenario_id, branch_id)
            allowed_by_branch[branch_id] = allowed

            if input.scenario_id == "generated-dungeon-basic-v1" and
                branch_id == branches.BRANCH_DUNGEON then
                allowed.MONS_GOBLIN = true
                allowed.MONS_KOBOLD = true
            end
        end

        if not allowed[source_id] and not origin and
            not arrival then
            error("saved floor has unsupported corpse " .. source_id)
        end

        local profile = roster.profile(corpse.monster_id)
        local definition = catalog.get("monsters", corpse.monster_id)
        local original = catalog.get("monsters", original_id)
        local source = catalog.get("monsters", source_id)
        local colored_job = draconian_base.is_job(original_id) and
            draconian_base.valid_color(corpse.monster_id) and
            corpse.death_kind_id == original_id and
            (origin or corpse.monster_id == draconian_base.for_job(original_id))

        if definition.average_hp_10x ~= profile.average or
            not definition.leaves_corpse or
            source.status ~= "defined" or
            (original.species_id ~= corpse.monster_id and
                not colored_job) then
            error("item " .. ctx:id(entity) .. " has impossible " .. corpse.monster_id .. " corpse")
        end

        if item.kind_id == "CORPSE_SKELETON" and flag(definition, "M_NO_SKELETON") then
            error("item " .. ctx:id(entity) .. " has impossible " .. corpse.monster_id .. " skeleton")
        end
    end

    -- A marker detached from its ordinary body must not evade the loop
    -- above and later become a remotely resurrectable forged entity.
    for _, entity in ipairs(ctx:query({ component.BEOGH_CORPSE })) do
        beogh_corpse.validate(ctx, entity)
    end

    return {}
end

register.policy({
    id = "save.validate_corpses",
    run = module.run,
})

return module
