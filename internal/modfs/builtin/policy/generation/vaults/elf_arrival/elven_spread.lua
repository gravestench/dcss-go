-- This mapless Elf:1 PLACE choice spends its selection on one ordinary
-- Elf room. It is a source alternative to an explicit border-check MAP.
local families = require("constants.vault_families")
local tags = require("constants.vault_tags")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")

local handler = {}
local VAULT_ID = "elven_spread"
local CHILD_RECORD = "elven_spread_child"

-- Place exactly the one child requested by the source post-place hook.
local function place(api)
    local options = {
        family = families.ELF,
    }

    local count, ids = api:place_maps(tags.MISC_ELF_VAULT, 1, options)

    if count ~= 1 then
        error("Elf spread has no eligible misc Elf room")
    end

    -- Save the exact child picked by this controller. Later ordinary
    -- placement may add another room with the same tag, so a tag alone
    -- cannot prove which map the source controller actually selected.
    local child = api.placed[#api.placed]

    child.records[#child.records + 1] = {
        kind = effects.GENERATION_RULE,
        identity = CHILD_RECORD,
        source_id = api.controller_id,
        vault_id = api.controller_id,
        x = 0,
        y = 0,
        pending = false,
        arguments = {
            child_id = ids[1],
        },
    }
end

handler.place = place

-- The mapless source choice must retain at least one misc Elf child in
-- saved history. Other optional Elf rooms may share this source tag.
local function validate(level)
    local selected_ids = {}

    for _, id in ipairs(level.vault_ids or {}) do
        selected_ids[id] = true
    end

    for _, record in ipairs(level.vault_records or level.records or {}) do
        if record.kind == effects.GENERATION_RULE and
            record.identity == CHILD_RECORD and
            record.source_id == VAULT_ID then
            local child_id = record.arguments and
                record.arguments.child_id
            local definition = child_id and catalog.get(child_id)

            if definition and selected_ids[child_id] and
                definition.family == families.ELF and
                definition.tags[tags.MISC_ELF_VAULT] then
                return true
            end
        end
    end

    error("Elf spread needs its recorded misc Elf child")
end

handler.validate = validate

return handler
