local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local items = require("ids.items")
local object_classes = require("ids.object_classes")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local roster = require("policy.population.roster")
local pool = require("policy.population.pool")

local policy = {}

function policy.read()
    local monster = catalog.get(categories.MONSTERS, monsters.MONS_TEST_MOSS)
    local spell = catalog.get(categories.SPELLS, spells.SPELL_TEST_SPARK)
    local item = catalog.get(categories.ITEMS, items.UNRAND_TEST_RELIC)
    local token = catalog.get(categories.ITEMS, items.MY_MOD_TOKEN)
    local allowed = roster.allowed("generated-dungeon-basic-v1")
    local choices = pool.at_depth(1, allowed, "generated-dungeon-basic-v1")
    local moss_weight = 0

    for _, choice in ipairs(choices) do
        if choice.id == monsters.MONS_TEST_MOSS then
            moss_weight = moss_weight + choice.weight
        end
    end

    return {
        monster = monster.name,
        spell = spell.name,
        item = item.name,
        item_class = token.class,
        known_class = object_classes.OBJ_TEST_RELICS,
        moss_allowed = allowed[monsters.MONS_TEST_MOSS],
        moss_weight = moss_weight,
        moss_hp = roster.profile(monsters.MONS_TEST_MOSS).average,
    }
end

register.policy({
    id = "test.content",
    run = policy.read,
})

return policy
