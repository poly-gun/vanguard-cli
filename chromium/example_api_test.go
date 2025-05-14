package chromium_test

import (
	"context"
	"log/slog"
	"vanguard-interface/chromium"
)

func ExampleLatest() {
	ctx := context.Background()

	v, e := chromium.Latest(ctx)
	if e != nil {
		slog.ErrorContext(ctx, "Error Getting Latest Chromium Version(s)", slog.String("error", e.Error()))
		panic(e)
	}

	_ = v
	
	//
	//switch v.(type) {
	//case map[string]interface{}, []interface{}:
	//	t.Logf("Verified Marshalled Response")
	//default:
	//	t.Errorf("Unexpected type %T", v)
	//}
	//
	//content, e := json.MarshalIndent(v, "", "    ")
	//if e != nil {
	//	t.Fatalf("Unexpected Test Error: %v", e)
	//}
	//
	//t.Logf("Response:\n%s", string(content))
	//
	//fmt.Printf("Example Magenta Color Output: %s\n", v)

	// // Output: Default
	// // Red
	// // Blue
	// // Green
	// // Cyan
	// // Color-1 Color-2 Color-3
	// // Example Magenta Color Output: Magenta
}
