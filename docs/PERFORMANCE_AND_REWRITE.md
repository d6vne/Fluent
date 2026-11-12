# Fluent rewrite: performance and compatibility

This branch is a compatibility-first refactor of Fluent Renewed Plus. It is not a claim that the entire UI has been rewritten or that FPS has been benchmarked.

## Public API preserved
- `Fluent:CreateWindow({...})`
- `Window:CreateTab({...})`, `Tab:AddSection(...)`
- Element constructors and `:SetValue(...)` for toggles, sliders, dropdowns and keybinds
- `SaveManager` and `InterfaceManager` integration

## Behavior
- `CreateWindow({ Animations = false })` is the default: toggle and element-hover effects use direct property changes.
- `Animations = true` opts back into these effects.
- Window drag/resize writes the current pointer position directly; Flipper is synchronized once on release.
- Keybind controls share a single input router, which unregisters listeners on control destruction.
- Dropdown options are built lazily; each popup owns its connections and destroys them when rebuilt.
- The theme registry uses weak instance keys and applies new colors without per-property spawned jobs.
- UI constructors parent instances after applying child and theme properties, limiting repeated layout work.

## Validate in an actual Roblox client
Automated CI only builds/bundles Luau. It does not exercise UI input or render frames.

1. Create the same number of controls in the optimized release and this rewrite build.
2. Record `os.clock()` around window/tab/control creation (5 trials, report median).
3. Drag window quickly for 10 seconds; verify pointer tracking, no jumps at maximize/restore, and mouse/touch release.
4. Open dropdowns with 20 / 200 / 1,000 entries; type queries, select from full rows, and change values.
5. Change themes repeatedly; inspect errors, CPU spikes, and UI visibility.
6. Press keybinds with input focus and without, capture a new key, switch modes, then destroy.
7. Repeat UI load/unload 20 times; compare total Lua heap and instance counts.
8. Use Roblox MicroProfiler frame timings for all comparisons; do not infer FPS from source size.

## Future work
- Virtualize dropdown option lists for thousands of rows rather than constructing every item.
- Audit notification timers and sound lifetime.
- Consolidate animation ownership and add cancellation.
- Introduce integration tests in Studio for touch, maximize, theme changes and config persistence.
- Replace the remaining singleton component state with per-window ownership.

## Attribution
The repository is MIT-licensed; keep the existing original copyright/license and credits when distributing modified versions.
