-- _economics_or_politics_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_economics_or_politics_",
    entries = {
        {
            weight = 10,
            text = "Amortisation",
        },
        {
            weight = 10,
            text = "Animal Spirits",
        },
        {
            weight = 10,
            text = "Bankruptcy",
        },
        {
            weight = 10,
            text = "Collusion",
        },
        {
            weight = 10,
            text = "Compound Interest",
        },
        {
            weight = 10,
            text = "Currency",
        },
        {
            weight = 10,
            text = "Debt",
        },
        {
            weight = 10,
            text = "Deflation",
        },
        {
            weight = 10,
            text = "Demand",
        },
        {
            weight = 10,
            text = "Dividends",
        },
        {
            weight = 10,
            text = "Exchange",
        },
        {
            weight = 10,
            text = "Growth",
        },
        {
            weight = 10,
            text = "Income",
        },
        {
            weight = 10,
            text = "Inflation",
        },
        {
            weight = 10,
            text = "Luxury",
        },
        {
            weight = 10,
            text = "Profit",
        },
        {
            weight = 10,
            text = "Risk Management",
        },
        {
            weight = 10,
            text = "Supply",
        },
        {
            weight = 10,
            text = "Taxation",
        },
        {
            weight = 10,
            text = "Valuable Assets",
        },
        {
            weight = 10,
            text = "Welfare",
        },
        {
            weight = 10,
            text = "Attainder",
        },
        {
            weight = 10,
            text = "Breach",
        },
        {
            weight = 10,
            text = "Checks and Balances",
        },
        {
            weight = 10,
            text = "Conservatism",
        },
        {
            weight = 10,
            text = "Defenestration",
        },
        {
            weight = 10,
            text = "Fee Simple",
        },
        {
            weight = 10,
            text = "Freehold",
        },
        {
            weight = 10,
            text = "Fundamental Breach",
        },
        {
            weight = 10,
            text = "Governance",
        },
        {
            weight = 10,
            text = "Greatest Utility",
        },
        {
            weight = 10,
            text = "Impeachment",
        },
        {
            weight = 10,
            text = "Mandamus",
        },
        {
            weight = 10,
            text = "Popular Demand",
        },
        {
            weight = 10,
            text = "Poverty",
        },
        {
            weight = 10,
            text = "Radicalism",
        },
        {
            weight = 10,
            text = "Reapportionment",
        },
        {
            weight = 10,
            text = "Royalism",
        },
        {
            weight = 10,
            text = "Sequestration",
        },
        {
            weight = 10,
            text = "Termination",
        },
        {
            weight = 10,
            text = "Wealth",
        },
        {
            weight = 10,
            text = "the Common Good",
        },
        {
            weight = 10,
            text = "the Dark Horse",
        },
        {
            weight = 10,
            text = "the Demagogue",
        },
        {
            weight = 10,
            text = "the Imperium",
        },
        {
            weight = 10,
            text = "the Lame Duck",
        },
        {
            weight = 10,
            text = "the Lesser Evil",
        },
        {
            weight = 10,
            text = "the Little People",
        },
        {
            weight = 10,
            text = "the People",
        },
        {
            weight = 10,
            text = "the Revolution",
        },
        {
            weight = 10,
            text = "the Silent Majority",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
