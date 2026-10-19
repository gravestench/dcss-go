-- _philosophy_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_philosophy_name_",
    entries = {
        {
            weight = 10,
            text = "Absolutism",
        },
        {
            weight = 10,
            text = "Abstinence",
        },
        {
            weight = 10,
            text = "Activism",
        },
        {
            weight = 10,
            text = "Agnosticism",
        },
        {
            weight = 10,
            text = "Altruism",
        },
        {
            weight = 10,
            text = "Anarchy",
        },
        {
            weight = 10,
            text = "Asceticism",
        },
        {
            weight = 10,
            text = "Atheism",
        },
        {
            weight = 10,
            text = "Autotheism",
        },
        {
            weight = 10,
            text = "Cynicism",
        },
        {
            weight = 10,
            text = "Disestablishmentarianism",
        },
        {
            weight = 10,
            text = "Dogma",
        },
        {
            weight = 10,
            text = "Egalitarianism",
        },
        {
            weight = 10,
            text = "Elitism",
        },
        {
            weight = 10,
            text = "Ethics",
        },
        {
            weight = 10,
            text = "Existentialism",
        },
        {
            weight = 10,
            text = "Fallacy",
        },
        {
            weight = 10,
            text = "Fanaticism",
        },
        {
            weight = 10,
            text = "Free Expression",
        },
        {
            weight = 10,
            text = "Free Will",
        },
        {
            weight = 10,
            text = "Hedonism",
        },
        {
            weight = 10,
            text = "Henotheism",
        },
        {
            weight = 10,
            text = "Heresy",
        },
        {
            weight = 10,
            text = "Idealism",
        },
        {
            weight = 10,
            text = "Levity",
        },
        {
            weight = 10,
            text = "Liberalism",
        },
        {
            weight = 10,
            text = "Limitation",
        },
        {
            weight = 10,
            text = "Monotheism",
        },
        {
            weight = 10,
            text = "Morality",
        },
        {
            weight = 10,
            text = "Mutualism",
        },
        {
            weight = 10,
            text = "Mysticism",
        },
        {
            weight = 10,
            text = "Nihilism",
        },
        {
            weight = 10,
            text = "Optimism",
        },
        {
            weight = 10,
            text = "Orthodoxy",
        },
        {
            weight = 10,
            text = "Panentheism",
        },
        {
            weight = 10,
            text = "Pantheism",
        },
        {
            weight = 10,
            text = "Pessimism",
        },
        {
            weight = 10,
            text = "Polytheism",
        },
        {
            weight = 10,
            text = "Pragmatism",
        },
        {
            weight = 10,
            text = "Rationality",
        },
        {
            weight = 10,
            text = "Relativism",
        },
        {
            weight = 10,
            text = "Serendipity",
        },
        {
            weight = 10,
            text = "Skepticism",
        },
        {
            weight = 10,
            text = "Sophism",
        },
        {
            weight = 10,
            text = "Stoicism",
        },
        {
            weight = 10,
            text = "Syndicalism",
        },
        {
            weight = 10,
            text = "the Ego",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
