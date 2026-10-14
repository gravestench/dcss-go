package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/content/monsterbookimport"
)

func main() {
	source := flag.String("source", "", "pinned C++ source directory")
	out := flag.String(
		"out",
		"internal/content/generated/monster-spellbooks.json",
		"committed monster spellbook path",
	)
	check := flag.Bool("check", false, "verify committed bytes without writing")
	flag.Parse()

	if err := monsterbookimport.Write(*source, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
