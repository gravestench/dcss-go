-- Pin one small authored arrival so the ECS marker lifecycle can be
-- checked without searching seeds for a rare Spider room.
local selection = {}

-- This fixture changes selection only; it uses the production DES parser.
local function choose_catalog()
    return {
        id = "fixture_spider_trigger_arrival",
    }
end

-- Supplemental maps would add unrelated actors or marker behavior.
local function choose_tag()
    return nil
end

selection.choose_catalog = choose_catalog
selection.choose_tag = choose_tag

return selection
