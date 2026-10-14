package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/content/monsterimport"
)

func main() {
	source := flag.String("source", "", "pinned C++ source directory")
	out := flag.String("out", "internal/content/generated/monsters.json", "committed monster catalog path")
	check := flag.Bool("check", false, "verify committed bytes without writing")
	flag.Parse()
	if err := monsterimport.Write(*source, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
