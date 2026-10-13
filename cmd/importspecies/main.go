package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/content/speciesimport"
)

func main() {
	source := flag.String("source", "", "pinned crawl-ref/source directory")
	out := flag.String("out", "", "generated species artifact path")
	check := flag.Bool("check", false, "verify the output is current without writing it")
	flag.Parse()
	if err := speciesimport.Write(*source, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
