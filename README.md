# Fluent Renewed Plus

![Fluent Renewed Title](Assets/darkmode.png#gh-dark-mode-only)
![Fluent Renewed Title](Assets/darkmode.png#gh-light-mode-only)

## Performance-focused Fluent fork

This repository maintains a compatibility-oriented Fluent fork with optimizations for drag latency, dropdown handling, theme updates, UI construction, and cleanup.

### Installation

The latest **published** optimization release can be loaded with:

```lua
local Fluent = loadstring(game:HttpGetAsync(
    "https://github.com/d6vne/Fluent/releases/latest/download/Fluent.luau"
))()
```

For reproducible deployments, use a pinned release tag rather than `latest`. The draft rewrite branch is **not** the published release.

### API compatibility

`Fluent:CreateWindow`, tabs, sections, and existing element constructors remain supported.
Animations are disabled by default in the rewrite branch to prioritize responsiveness. To opt in:

```lua
local Window = Fluent:CreateWindow({
    Title = "My UI",
    Size = UDim2.fromOffset(650, 500),
    Theme = "Dark",
    Animations = true,
})
```

The Addons/SaveManager and Addons/InterfaceManager remain available. See [rewrite notes](docs/PERFORMANCE_AND_REWRITE.md) for testing instructions and remaining work.

### Examples

- [Studio example](Example.client.luau)
- [Client example](Example.luau)

## Credits

- [Adiont](https://github.com/Adi0nt/Fluent-Renewed-Plus) - The master mind behind Fluent Renewed Plus
- [Master Oogway](https://github.com/ActualMasterOogway/Fluent-Renewed) - The master mind behind Fluent Renewed
- [dawid](https://github.com/dawid-scripts/Fluent) - The master mind behind Fluent
- [Lucide](https://github.com/lucide-icons), [Phosphor](https://github.com/phosphor-icons) - The sexy icons
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) - Assets for the UI, some of the code
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) - Code for most of the elements, save manager
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic) - Porting richie0866's acrylic module to lua
- [Latte Softworks & Kotera](https://github.com/latte-soft/wax/) - Bundler
- [Pepsied-5229/Pepsi-UI-Library](https://github.com/Pepsied-5229/Pepsi-UI-Library) - Inspiration for new features, some of the code
