package game

import (
	"strconv"
	"testing"
)

// An artefact's appearance and later true name belong to that item. The
// ordinary Identify action must persist both its type and property discovery.
func TestArtefactDiscoverySurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	item := addIdentificationTestItem(t, g, "WPN_DAGGER", true)
	scroll := addIdentificationTestItem(t, g, "SCR_IDENTIFY", true)

	weapon, _ := g.stores.Items.Get(item)

	weapon.Plus = 5

	artefacts := g.scripts.Components()["item.artefact"]

	if _, err := artefacts.Set(item, map[string]any{
		"kind":       "random",
		"unique_id":  "",
		"seed":       uint64(12345),
		"name":       "dagger \"Zog\"",
		"appearance": "non-descript dagger",
		"brand":      "SPWPN_VENOM",
		"properties": map[string]any{
			"ARTP_FIRE": int64(1),
		},

		"known": map[string]any{
			"ARTP_FIRE": false,
		},

		"flags": []any{},
	}); err != nil {
		t.Fatal(err)
	}

	if name := itemNameInInventory(t, g, item); name != "non-descript dagger" {
		t.Fatalf("unidentified artefact name = %q", name)
	}

	hidden, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer hidden.Close()

	if name := itemNameInInventory(t, hidden, item); name != "non-descript dagger" {
		t.Fatalf("restored hidden artefact name = %q", name)
	}

	result, err := g.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: strconv.FormatUint(uint64(item), 10),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Identify spent %d aut", result.Spent)
	}

	if name := itemNameInInventory(t, g, item); name != "+5 dagger \"Zog\"" {
		t.Fatalf("identified artefact name = %q", name)
	}

	identified, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer identified.Close()

	if name := itemNameInInventory(t, identified, item); name != "+5 dagger \"Zog\"" {
		t.Fatalf("restored identified artefact name = %q", name)
	}

	state, found := identified.scripts.Components()["item.artefact"].Get(item)

	if !found {
		t.Fatal("identified item lost artefact state")
	}

	value, err := state.Get("known")

	if err != nil {
		t.Fatal(err)
	}

	known := value.(map[string]any)

	if known["ARTP_FIRE"] != true {
		t.Fatal("Identify lost discovered artefact property")
	}
}
