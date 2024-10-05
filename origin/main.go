package main

import (
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
)

func main() {
	http.HandleFunc("/", handleReq)
	log.Fatal(http.ListenAndServe(":8081", nil))
}

func handleReq(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	log.Printf("Request received for path: %s", path)

	if strings.HasSuffix(path, ".ts") {
		serveSegment(w, r)
		return
	}

	http.NotFound(w, r)
}

func serveSegment(w http.ResponseWriter, r *http.Request) {
	regx := regexp.MustCompile(`(\d+)\.ts$`)
	match := regx.FindStringSubmatch(r.URL.Path)
	if match == nil {
		http.NotFound(w, r)
		return
	}

	currSegment, _ := strconv.Atoi(match[1])
	nextSegment := currSegment + 1

	w.Header().Set("Content-Type", "video/MP2T")
	w.Header().Set("Link", fmt.Sprintf("<%d.ts>; rel=\"next\"", nextSegment))

	tsContent := []byte(fmt.Sprintf("Segment %d", currSegment))
	w.Write(tsContent)
}
