package main

import (
	"fmt"
	"strings"
)

// modDirs preserves flag order because later Lua layers override earlier ones.
type modDirs []string

func (dirs *modDirs) String() string {
	return strings.Join(*dirs, ", ")
}

func (dirs *modDirs) Set(value string) error {
	if strings.TrimSpace(value) == "" {
		return fmt.Errorf("mod directory must not be empty")
	}

	*dirs = append(*dirs, value)

	return nil
}
