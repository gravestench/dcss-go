package game

import (
	"strings"
	"testing"
)

func TestLignificationInFireCloudRequiresConfirmation(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	item, _ := g.stores.Items.Get(potionID(t, g))

	item.KindID = "POT_LIGNIFY"

	position, _ := g.stores.Positions.Get(g.player)
	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["world.cloud"].Set(cloud, map[string]any{
		"kind_id":         "CLOUD_FIRE",
		"source_actor_id": uint64(g.player),
		"kill_category":   "KC_YOU",
		"killer_type":     "KILL_YOU_MISSILE",
		"level_id":        int64(position.LevelID),
		"x":               int64(position.X),
		"y":               int64(position.Y),
		"decay_aut":       int64(1000),
	})

	if err != nil {
		t.Fatal(err)
	}

	before := g.currentAut
	command := Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	}

	result, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		!strings.Contains(result.Confirmation, "damaging cloud") ||
		g.currentAut != before || item.KindID != "POT_LIGNIFY" {
		t.Fatalf("unconfirmed tree quaff = %+v", result)
	}

	command.Forced = true
	result, err = g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 || result.Confirmation != "" {
		t.Fatalf("confirmed tree quaff = %+v", result)
	}
}
