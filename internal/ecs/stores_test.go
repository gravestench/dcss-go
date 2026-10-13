package ecs

import (
	"errors"
	"testing"

	"github.com/gravestench/akara"
)

func TestRegisterStoresAreWorldLocal(t *testing.T) {
	firstWorld := akara.NewWorld()
	defer firstWorld.Close()
	secondWorld := akara.NewWorld()
	defer secondWorld.Close()

	first := Register(firstWorld)
	second := Register(secondWorld)
	entity, err := firstWorld.CreateEntity()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := first.Positions.Set(entity, Position{LevelID: 1, X: 2, Y: 3}); err != nil {
		t.Fatal(err)
	}
	if _, found := second.Positions.Get(entity); found {
		t.Fatal("position leaked into another world")
	}
	if _, err := secondWorld.Subscribe(akara.All(first.Positions)); !errors.Is(err, akara.ErrForeignComponent) {
		t.Fatalf("foreign store subscription error = %v, want ErrForeignComponent", err)
	}
}
