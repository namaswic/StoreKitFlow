# Contributing to StoreKitFlow

Thanks for your interest in contributing. Whether you're fixing a bug, improving the Guide, or adding a new Explorer modifier — all contributions are welcome.

---

## Getting Started

1. Fork the repo and clone it locally
2. Open `DemoApp/StoreKitFlowDemo/StoreKitFlowDemo.xcodeproj` in Xcode
3. Select the **StoreKitFlowDemo** scheme and choose an iPhone simulator
4. Run the app — everything works out of the box with the included `.storekit` configuration file

The demo app is the main development environment. All library code lives in `Sources/StoreKitFlow/`.

---

## Project Structure

```
Sources/StoreKitFlow/
├── Interface/        # Public API — store, protocols, configuration, models
├── Implementation/   # Internal services — purchasing, entitlements, cache, logging
└── UI/               # Explorer, Guide, Logs, Cache screens and shared components

DemoApp/              # Standalone demo app that imports StoreKitFlow as a local package
```

---

## Ways to Contribute

### Fix a bug
Open an issue describing what you expected vs what happened, then submit a PR with the fix. Include steps to reproduce if possible.

### Add a new Explorer modifier
Each StoreKit view screen (e.g. `SKSubscriptionStoreViewScreen.swift`) lists modifiers as rows in a `Form`. Adding a new one means:
- Adding a case to the relevant option enum in `ExplorerOptionEnums.swift`
- Adding a `Picker` or `Toggle` row in the screen file
- Wiring it into the view being previewed

### Expand the Guide
The Guide is a scrollable list of educational sections in `Sources/StoreKitFlow/UI/Info/InfoScreen.swift`. Each section is a `InfoSection` with a title, icon, and body text. If something in StoreKit is confusing or underdocumented, it probably belongs here.

### Improve documentation
If something in `GETTING_STARTED.md`, the README, or a doc comment is unclear or missing — fix it.

---

## Guidelines

- **No third-party dependencies.** StoreKitFlow is intentionally pure Swift + StoreKit + Combine.
- **Keep `@MainActor` guarantees.** All store methods and cache operations are `@MainActor`. Don't introduce background threading without discussion.
- **Public API changes need an issue first.** If you're adding or changing something in `Interface/`, open an issue to discuss before writing code.
- **Small, focused PRs.** One thing per PR makes review faster and merges cleaner.
- **Test in the simulator.** Run the demo app with the included StoreKit config and verify your change works end-to-end before submitting.
