package game

import (
	"fmt"
	"reflect"
	"testing"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/script"
	"github.com/gravestench/akara"
)

func TestEveryLegalCharacterChoiceIsPlayable(t *testing.T) {
	rules, err := modfs.Load("")

	if err != nil {
		t.Fatal(err)
	}

	_, choices, err := script.ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	legal := 0
	mismatches := 0
	examples := make([]string, 0, 5)

	for pair, choice := range choices {
		if !pair.SpeciesFirst {
			continue
		}

		allowed := choice.Restriction != "banned"

		if allowed {
			legal++
		}

		if choice.Playable != allowed {
			mismatches++

			if len(examples) < cap(examples) {
				examples = append(examples, fmt.Sprintf(
					"%s/%s: legal=%t playable=%t",
					pair.SpeciesID,
					pair.JobID,
					allowed,
					choice.Playable,
				))
			}
		}
	}

	if mismatches > 0 {
		t.Errorf("%d character choices disagree with source legality; examples: %v",
			mismatches,
			examples,
		)
	}

	if legal < 100 {
		t.Fatalf("only %d legal choices reached the menu", legal)
	}
}

func TestDistinctCharacterStartFamiliesReachDungeon(t *testing.T) {
	tests := []struct {
		name      string
		speciesID string
		jobID     string
		weaponID  string
		skillID   string
		religion  string
		spellID   string
		maxMP     int
	}{
		{
			name:      "caster with no weapon choice",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_FIRE_ELEMENTALIST",
			skillID:   "SK_FIRE_MAGIC",
			spellID:   "SPELL_FOXFIRE",
			maxMP:     3,
		},

		{
			name:      "fixed weapon",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_HUNTER",
			skillID:   "SK_RANGED_WEAPONS",
			maxMP:     1,
		},

		{
			name:      "restricted gear",
			speciesID: "SP_FELID",
			jobID:     "JOB_FIGHTER",
			weaponID:  "WPN_UNARMED",
			skillID:   "SK_UNARMED_COMBAT",
			maxMP:     2,
		},

		{
			name:      "god linked",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_BERSERKER",
			weaponID:  "WPN_HAND_AXE",
			skillID:   "SK_AXES",
			religion:  "GOD_TROG",
			maxMP:     1,
		},

		{
			name:      "forced chaos brand",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_CHAOS_KNIGHT",
			weaponID:  "WPN_HAND_AXE",
			skillID:   "SK_AXES",
			religion:  "GOD_XOM",
			maxMP:     1,
		},

		{
			name:      "innate caster",
			speciesID: "SP_DJINNI",
			jobID:     "JOB_FIRE_ELEMENTALIST",
			skillID:   "SK_SPELLCASTING",
			spellID:   "SPELL_FOXFIRE",
			maxMP:     0,
		},

		{
			name:      "wanderer",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_WANDERER",
			maxMP:     -1,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			started, err := NewDungeonGame(
				43,
				tc.speciesID,
				tc.jobID,
				tc.weaponID,
				"Tester",
			)

			if err != nil {
				t.Fatal(err)
			}

			defer started.Close()

			if started.View().PlayerHP < 1 {
				t.Fatal("character has no starting HP")
			}

			view := started.View()

			if tc.speciesID == "SP_DJINNI" {
				for _, item := range view.Inventory {
					if item.KindID == "POT_MAGIC" {
						t.Fatal("HP-casting Djinni received a useless magic potion")
					}
				}
			}

			if tc.maxMP >= 0 && view.PlayerMaxMP != tc.maxMP {
				t.Fatalf("starting MP = %d, want %d", view.PlayerMaxMP, tc.maxMP)
			}

			if tc.skillID != "" {
				found := false

				for _, skill := range view.Skills {
					found = found || skill.ID == tc.skillID
				}

				if !found {
					t.Fatalf("start lacks %s: %+v", tc.skillID, view.Skills)
				}
			}

			originStore := started.scripts.Components()["character.origin"]
			origin, found := originStore.Get(started.player)

			if !found {
				t.Fatal("start lacks durable Lua origin")
			}

			god, err := origin.Get("religion")

			if err != nil {
				t.Fatal(err)
			}

			wantGod := tc.religion

			if wantGod == "" {
				wantGod = "GOD_NO_GOD"
			}

			if god != wantGod {
				t.Fatalf("starting god = %v, want %s", god, wantGod)
			}

			spells := playerSpellRecords(t, started)

			if tc.spellID != "" && spells[tc.spellID].KnownSlot == 0 {
				t.Fatalf("starting spell %s is not known", tc.spellID)
			}

			if tc.speciesID == "SP_DJINNI" {
				future := 0

				for _, spell := range spells {
					if spell.FutureLevel > 0 {
						future++
					}
				}

				if future != 13 {
					t.Fatalf("Djinni has no durable future spell list: %v", future)
				}
			}

			before := started.Snapshot()
			restored, err := Restore(before)

			if err != nil {
				t.Fatalf("start did not survive save and restore: %v", err)
			}

			defer restored.Close()

			if restored.View().PlayerHP != started.View().PlayerHP {
				t.Fatal("starting HP changed after restore")
			}

			restoredOrigin, found := restored.scripts.Components()["character.origin"].Get(
				restored.player,
			)

			if !found {
				t.Fatal("restore lost character origin")
			}

			for _, field := range []string{
				"initial_skills",
				"innate_mutations",
				"religion",
				"piety",
				"gift_timeout",
			} {
				beforeValue, beforeErr := origin.Get(field)
				afterValue, afterErr := restoredOrigin.Get(field)

				if beforeErr != nil ||
					afterErr != nil ||
					beforeValue != afterValue {
					t.Fatalf("restore changed %s: %v to %v", field, beforeValue, afterValue)
				}
			}

			if !reflect.DeepEqual(spells, playerSpellRecords(t, restored)) {
				t.Fatal("restore changed starting spell records")
			}
		})
	}
}

func TestRestrictedSpeciesStartEquipmentAndSpells(t *testing.T) {
	cases := []struct {
		name         string
		species      string
		job          string
		weapon       string
		missingItem  string
		missingSpell string
	}{
		{
			name:    "Octopode cannot wear body armour",
			species: "SP_OCTOPODE",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_FLAIL",
		},

		{
			name:         "Formicid stasis discards blink scroll and spell",
			species:      "SP_FORMICID",
			job:          "JOB_WARPER",
			weapon:       "WPN_MACE",
			missingItem:  "SCR_BLINKING",
			missingSpell: "SPELL_BLINK",
		},

		{
			name:    "Formicid can use quarterstaff and shield",
			species: "SP_FORMICID",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_QUARTERSTAFF",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			started, err := NewDungeonGame(43, tc.species, tc.job, tc.weapon, "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer started.Close()

			slots := make(map[string]string)

			for _, item := range started.View().Inventory {
				if item.KindID == tc.missingItem && tc.missingItem != "" {
					t.Fatalf("received useless item %s", item.KindID)
				}

				if item.Slot != "" {
					slots[item.Slot] = item.KindID
				}
			}

			if tc.species == "SP_OCTOPODE" && slots["body"] != "" {
				t.Fatalf("Octopode wears %s", slots["body"])
			}

			if tc.weapon == "WPN_QUARTERSTAFF" &&
				(slots["weapon"] != tc.weapon || slots["shield"] == "") {
				t.Fatalf("Formicid equipment = %v", slots)
			}

			spells := playerSpellRecords(t, started)
			hasBlockedSpell := tc.missingSpell != "" &&
				spells[tc.missingSpell].KnownSlot != 0

			if hasBlockedSpell {
				t.Fatalf("memorized useless spell %s", tc.missingSpell)
			}

			restored, err := Restore(started.Snapshot())

			if err != nil {
				t.Fatalf("start does not restore: %v", err)
			}

			restored.Close()
		})
	}
}

func TestWandererGiftsAcrossSpeciesAndSeeds(t *testing.T) {
	species := []string{
		"SP_HUMAN",
		"SP_FELID",
		"SP_OCTOPODE",
		"SP_FORMICID",
		"SP_DJINNI",
		"SP_GHOUL",
		"SP_MUMMY",
		"SP_GARGOYLE",
		"SP_TENGU",
		"SP_TROLL",
	}

	for _, speciesID := range species {
		t.Run(speciesID, func(t *testing.T) {
			for seed := uint64(1); seed <= 8; seed++ {
				started, err := NewDungeonGame(
					seed,
					speciesID,
					"JOB_WANDERER",
					"",
					"Tester",
				)

				if err != nil {
					t.Fatalf("seed %d: %v", seed, err)
				}

				restored, err := Restore(started.Snapshot())

				if err != nil {
					started.Close()
					t.Fatalf("seed %d restore: %v", seed, err)
				}

				restored.Close()
				started.Close()
			}
		})
	}
}

func TestEveryLegalCharacterStartReachesDungeon(t *testing.T) {
	rules, err := modfs.Load("")

	if err != nil {
		t.Fatal(err)
	}

	_, choices, err := script.ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := script.NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	failed := 0
	examples := make([]string, 0, 10)
	started := 0

	for pair, choice := range choices {
		if !pair.SpeciesFirst || choice.Restriction == "banned" {
			continue
		}

		result, optionErr := runtime.Policy("character.weapon_options", map[string]any{
			"species_id": pair.SpeciesID,
			"job_id":     pair.JobID,
		})

		if optionErr != nil {
			t.Fatal(optionErr)
		}

		weaponID := ""
		options, ok := result["options"].([]any)

		if !ok {
			empty, valid := result["options"].(map[string]any)

			if !valid || len(empty) != 0 {
				t.Fatalf("%s/%s has malformed weapon options: %T",
					pair.SpeciesID,
					pair.JobID,
					result["options"],
				)
			}
		}

		if len(options) > 0 {
			first, valid := options[0].(map[string]any)

			if !valid {
				t.Fatal("malformed weapon option")
			}

			weaponID, valid = first["id"].(string)

			if !valid {
				t.Fatal("weapon option lacks an ID")
			}
		}

		g, startErr := NewDungeonGameWithRules(
			17,
			pair.SpeciesID,
			pair.JobID,
			weaponID,
			"Tester",
			rules,
		)

		if startErr != nil {
			failed++

			if len(examples) < cap(examples) {
				examples = append(examples, fmt.Sprintf(
					"%s/%s: %v",
					pair.SpeciesID,
					pair.JobID,
					startErr,
				))
			}

			continue
		}

		started++
		g.Close()
	}

	if failed > 0 {
		t.Errorf("%d legal starts failed; examples: %v", failed, examples)
	}

	if started < 100 {
		t.Fatalf("only %d legal starts reached the Dungeon", started)
	}
}

func TestCharacterStartRejectsInvalidWeaponAndBannedPair(t *testing.T) {
	for _, tc := range []struct {
		name      string
		speciesID string
		jobID     string
		weaponID  string
	}{
		{
			name:      "wrong Fighter upgrade",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_FIGHTER",
			weaponID:  "WPN_SPEAR",
		},

		{
			name:      "caster cannot choose",
			speciesID: "SP_HUMAN",
			jobID:     "JOB_FIRE_ELEMENTALIST",
			weaponID:  "WPN_RAPIER",
		},

		{
			name:      "source banned pair",
			speciesID: "SP_FELID",
			jobID:     "JOB_GLADIATOR",
			weaponID:  "WPN_UNARMED",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g, err := NewDungeonGame(
				3,
				tc.speciesID,
				tc.jobID,
				tc.weaponID,
				"Tester",
			)

			if err == nil {
				g.Close()
				t.Fatal("invalid character start was accepted")
			}
		})
	}
}

func TestWandererMagicGiftsAreSaved(t *testing.T) {
	withSpells := 0

	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewDungeonGame(seed, "SP_HUMAN", "JOB_WANDERER", "", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		spells := playerSpellRecords(t, g)
		library := false

		for _, state := range spells {
			if state.InLibrary {
				library = true
			}
		}

		if library {
			withSpells++
			loaded, restoreErr := Restore(g.Snapshot())

			if restoreErr != nil {
				g.Close()
				t.Fatalf("Wanderer spell gift did not survive restore: %v", restoreErr)
			}

			loadedSpells := playerSpellRecords(t, loaded)

			if !reflect.DeepEqual(loadedSpells, spells) {
				loaded.Close()
				g.Close()
				t.Fatalf("Wanderer spells changed from %v to %v", spells, loadedSpells)
			}

			loaded.Close()
		}

		g.Close()
	}

	if withSpells == 0 {
		t.Fatal("no Wanderer received a source-style spell gift")
	}
}
