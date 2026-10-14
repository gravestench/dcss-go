package game

import (
	"testing"

	"dcrawl-go/internal/content"
)

func testCatalog(t *testing.T) content.Catalog {
	t.Helper()
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}

	return catalog
}
