package game

import (
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

func TestMutationPotionQuaffAndSaveContinuation(t *testing.T) {
	g := newStepGame(t)

	itemID := carryCuring(t, g)
	item, found := g.stores.Items.Get(akara.Entity(itemID))

	if !found {
		t.Fatal("carried potion missing")
	}

	item.KindID = "POT_MUTATION"

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	command := Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	}

	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)

	if leftErr != nil {
		t.Fatal(leftErr)
	}

	if rightErr != nil {
		t.Fatal(rightErr)
	}

	if left.Spent != 10 ||
		g.world.EntityExists(akara.Entity(itemID)) ||
		!strings.Contains(left.Events[0].Text, "extremely strange") {
		t.Fatalf("mutation potion did not consume a turn and item: %+v", left)
	}

	if !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("mutation potion diverged after restore")
	}
}
