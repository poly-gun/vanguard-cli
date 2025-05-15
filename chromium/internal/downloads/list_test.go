package downloads_test

import (
	"encoding/json"
	"log/slog"
	"os"
	"testing"

	"vanguard-interface/chromium/internal/downloads"
)

func TestList(t *testing.T) {
	const level = slog.LevelDebug

	slog.SetLogLoggerLevel(level)

	options := &slog.HandlerOptions{AddSource: true, Level: level}
	handler := slog.NewJSONHandler(os.Stdout, options)
	logger := slog.New(handler)

	slog.SetDefault(logger)

	defer t.Cleanup(func() {
		t.Logf("%s", "Running Local Testing Clean-Up")
	})

	t.Run("JSON-Response", func(t *testing.T) {
		ctx := t.Context()

		v, e := downloads.List(ctx)
		if e != nil {
			t.Errorf("Error: %v", e)
		}

		content, e := json.MarshalIndent(v, "", "    ")
		if e != nil {
			t.Fatalf("Unexpected Test Error: %v", e)
		}

		t.Logf("Response:\n%s", string(content))

		f, e := os.OpenFile("chromium-latest-response.json", os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
		if e != nil {
			t.Fatalf("Unexpected Test Error: %v", e)
		}

		defer f.Close()

		encoder := json.NewEncoder(f)

		encoder.SetIndent("", "    ")

		if e := encoder.Encode(v); e != nil {
			t.Fatalf("Unexpected Test Error: %v", e)
		}
	})
}
