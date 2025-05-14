package chromium

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

func Latest(ctx context.Context) (interface{}, error) {
	const url = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"

	slog.DebugContext(ctx, "Latest URL Endpoint", slog.String("url", url))

	client := &http.Client{Timeout: time.Duration(15 * time.Second)}

	request, e := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if e != nil {
		slog.ErrorContext(ctx, "Unable to Generate Request", slog.String("error", e.Error()))
		return nil, e
	}

	response, e := client.Do(request)
	if e != nil {
		slog.ErrorContext(ctx, "Error Creating Response", slog.String("error", e.Error()))
		return nil, e
	}

	defer response.Body.Close()

	var buffer bytes.Buffer

	if _, e := io.Copy(&buffer, response.Body); e != nil {
		slog.ErrorContext(ctx, "Error Reading Response", slog.String("error", e.Error()))
		return nil, e
	}

	// Evaluate if the response is expected JSON.
	if v := response.Header.Get("Content-Type"); !(strings.Contains(strings.ToLower(v), "json")) {
		e := fmt.Errorf("content-type %s isn't json", v)

		slog.ErrorContext(ctx, "Unexpected Content-Type", slog.String("header", v), slog.String("error", e.Error()))

		return nil, e
	}

	var serial map[string]interface{}
	if e := json.Unmarshal(buffer.Bytes(), &serial); e != nil {
		slog.ErrorContext(ctx, "Error Unmarshaling Response", slog.String("error", e.Error()))
		return nil, e
	}

	return serial, nil
}
