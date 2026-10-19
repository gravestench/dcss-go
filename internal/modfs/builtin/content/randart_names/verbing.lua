-- _verbing_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_verbing_",
    entries = {
        {
            weight = 5,
            text = "Ageing",
        },
        {
            weight = 5,
            text = "Baking",
        },
        {
            weight = 10,
            text = "Bedazzling",
        },
        {
            weight = 10,
            text = "Bespelling",
        },
        {
            weight = 10,
            text = "Blushing",
        },
        {
            weight = 5,
            text = "Breathing",
        },
        {
            weight = 10,
            text = "Brewing",
        },
        {
            weight = 10,
            text = "Building",
        },
        {
            weight = 10,
            text = "Burning",
        },
        {
            weight = 5,
            text = "Bursting",
        },
        {
            weight = 10,
            text = "Changing",
        },
        {
            weight = 10,
            text = "Charming",
        },
        {
            weight = 10,
            text = "Chewing",
        },
        {
            weight = 10,
            text = "Conjuring",
        },
        {
            weight = 10,
            text = "Crafting",
        },
        {
            weight = 10,
            text = "Cursing",
        },
        {
            weight = 10,
            text = "Dancing",
        },
        {
            weight = 10,
            text = "Destroying",
        },
        {
            weight = 10,
            text = "Devouring",
        },
        {
            weight = 10,
            text = "Disbelieving",
        },
        {
            weight = 5,
            text = "Dripping",
        },
        {
            weight = 10,
            text = "Enchanting",
        },
        {
            weight = 10,
            text = "Enfolding",
        },
        {
            weight = 10,
            text = "Feeding",
        },
        {
            weight = 10,
            text = "Flying",
        },
        {
            weight = 10,
            text = "Forging",
        },
        {
            weight = 10,
            text = "Fortifying",
        },
        {
            weight = 10,
            text = "Freezing",
        },
        {
            weight = 10,
            text = "Gazing",
        },
        {
            weight = 5,
            text = "Glimmering",
        },
        {
            weight = 5,
            text = "Glowing",
        },
        {
            weight = 10,
            text = "Gnashing",
        },
        {
            weight = 10,
            text = "Grinning",
        },
        {
            weight = 10,
            text = "Growing",
        },
        {
            weight = 10,
            text = "Hammering",
        },
        {
            weight = 10,
            text = "Healing",
        },
        {
            weight = 10,
            text = "Holding",
        },
        {
            weight = 10,
            text = "Howling",
        },
        {
            weight = 5,
            text = "Hugging",
        },
        {
            weight = 10,
            text = "Hungering",
        },
        {
            weight = 10,
            text = "Hurling",
        },
        {
            weight = 10,
            text = "Hurting",
        },
        {
            weight = 10,
            text = "Hurtling",
        },
        {
            weight = 10,
            text = "Imbibing",
        },
        {
            weight = 10,
            text = "Inviting",
        },
        {
            weight = 10,
            text = "Jumping",
        },
        {
            weight = 10,
            text = "Kissing",
        },
        {
            weight = 10,
            text = "Keeping",
        },
        {
            weight = 10,
            text = "Leaping",
        },
        {
            weight = 10,
            text = "Loving",
        },
        {
            weight = 10,
            text = "Lusting",
        },
        {
            weight = 1,
            text = "Malding",
        },
        {
            weight = 10,
            text = "Mauling",
        },
        {
            weight = 10,
            text = "Mashing",
        },
        {
            weight = 10,
            text = "Muttering",
        },
        {
            weight = 10,
            text = "Nurturing",
        },
        {
            weight = 10,
            text = "Protecting",
        },
        {
            weight = 10,
            text = "Rescuing",
        },
        {
            weight = 10,
            text = "Riding",
        },
        {
            weight = 10,
            text = "Scorching",
        },
        {
            weight = 10,
            text = "Screaming",
        },
        {
            weight = 10,
            text = "Sharing",
        },
        {
            weight = 10,
            text = "Sheltering",
        },
        {
            weight = 10,
            text = "Shifting",
        },
        {
            weight = 10,
            text = "Shimmering",
        },
        {
            weight = 10,
            text = "Shouting",
        },
        {
            weight = 10,
            text = "Shrinking",
        },
        {
            weight = 10,
            text = "Singing",
        },
        {
            weight = 10,
            text = "Smoking",
        },
        {
            weight = 10,
            text = "Stopping",
        },
        {
            weight = 10,
            text = "Summoning",
        },
        {
            weight = 10,
            text = "Supporting",
        },
        {
            weight = 10,
            text = "Teaching",
        },
        {
            weight = 10,
            text = "Telling",
        },
        {
            weight = 10,
            text = "Thieving",
        },
        {
            weight = 10,
            text = "Threshing",
        },
        {
            weight = 10,
            text = "Transmuting",
        },
        {
            weight = 10,
            text = "Twisting",
        },
        {
            weight = 10,
            text = "Uplifting",
        },
        {
            weight = 10,
            text = "Usurping",
        },
        {
            weight = 10,
            text = "Winnowing",
        },
        {
            weight = 10,
            text = "Witching",
        },
        {
            weight = 10,
            text = "Wizarding",
        },
        {
            weight = 10,
            text = "Writhing",
        },
        {
            weight = 5,
            text = "Bashing",
        },
        {
            weight = 5,
            text = "Slashing",
        },
        {
            weight = 5,
            text = "Piercing",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
