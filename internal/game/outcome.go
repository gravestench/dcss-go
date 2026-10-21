package game

import "fmt"

// outcome asks Lua for the saved session result. Go only needs the generic
// terminal distinction to stop scheduling and select the right client page.
func (g *Game) outcome() (string, error) {
	result, err := g.scripts.Policy("session.outcome", nil)

	if err != nil {
		return "", err
	}

	kind, ok := result["kind"].(string)

	if !ok {
		return "", fmt.Errorf("session outcome is not text")
	}

	return kind, nil
}
