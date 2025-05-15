package downloads

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

const url = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"

type Versions struct {
	Channels struct {
		Beta struct {
			Channel   string `json:"channel"`
			Downloads struct {
				Chrome []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome"`
				ChromeHeadlessShell []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome-headless-shell"`
				Chromedriver []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chromedriver"`
			} `json:"downloads"`
			Revision string `json:"revision"`
			Version  string `json:"version"`
		} `json:"Beta"`
		Canary struct {
			Channel   string `json:"channel"`
			Downloads struct {
				Chrome []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome"`
				ChromeHeadlessShell []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome-headless-shell"`
				Chromedriver []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chromedriver"`
			} `json:"downloads"`
			Revision string `json:"revision"`
			Version  string `json:"version"`
		} `json:"Canary"`
		Dev struct {
			Channel   string `json:"channel"`
			Downloads struct {
				Chrome []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome"`
				ChromeHeadlessShell []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome-headless-shell"`
				Chromedriver []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chromedriver"`
			} `json:"downloads"`
			Revision string `json:"revision"`
			Version  string `json:"version"`
		} `json:"Dev"`
		Stable struct {
			Channel   string `json:"channel"`
			Downloads struct {
				Chrome []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome"`
				ChromeHeadlessShell []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chrome-headless-shell"`
				Chromedriver []struct {
					Platform string `json:"platform"`
					Url      string `json:"url"`
				} `json:"chromedriver"`
			} `json:"downloads"`
			Revision string `json:"revision"`
			Version  string `json:"version"`
		} `json:"Stable"`
	} `json:"channels"`
	Timestamp time.Time `json:"timestamp"`
}

func List(ctx context.Context) (*Versions, error) {
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

	var versions *Versions
	if e := json.Unmarshal(buffer.Bytes(), &versions); e != nil {
		slog.ErrorContext(ctx, "Error Unmarshalling Response", slog.String("error", e.Error()))
		return nil, e
	}

	return versions, nil
}
