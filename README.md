# PathWorks

[![](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![](https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-lightgrey)](#)
[![](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight Swift library that extends `String` and `[String]` with ergonomic file‑system path primitives. Build, decompose, sanitize, and compare paths.

---

## Installation

Add PathWorks to your `Package.swift`:

```swift
.package(url: "https://github.com/RuiNelson/PathWorks.git", from: "2.0.0")
```

Then add `"PathWorks"` to your target's dependencies:

```swift
.target(name: "YourTarget", dependencies: [.product(name: "PathWorks", package: "PathWorks")])
```

---

## Cookbook

### Build paths from components

```swift
["Users", "me", "Documents"].path                // Users/me/Documents
["Users", "me"].rootPath                         // /Users/me
["Users", "me"].backslashPath                    // Users\me
["Users", "me"].rootPathBackslash                // \Users\me
```

### Decompose a path

```swift
"/Users/me/file.swift".pathComponents            // ["Users", "me", "file.swift"]
"/Users/me/file.swift".lastPathComponent         // Optional("file.swift")
"/Users/me/file.swift".removingLastPathComponent // "/Users/me"
```

### Resolve `.` and `..` segments

`pathComponents` automatically resolves dot segments. For absolute paths, `..` cannot escape past root.

```swift
"a/./b".pathComponents                           // ["a", "b"]
"a/../b".pathComponents                          // ["b"]
"/a/b/../..".pathComponents                      // []  (resolves to root)
"/../a".pathComponents                           // ["a"]  (.. at root is a no-op)
"../a".pathComponents                            // ["..", "a"]  (preserved for relative paths)
```

### Append components (with dot resolution)

`appendingPathComponent` resolves `.` and `..` contextually against the base path.

```swift
"/Users".appendingPathComponent("me")            // "/Users/me"
"ab/cd/".appendingPathComponent("ef")            // "ab/cd/ef"
"a/b".appendingPathComponent("..")               // "a"
"a/b".appendingPathComponent("../c")             // "a/c"
"/a/b".appendingPathComponent("../../c")         // "/c"
"/var".appendingPathComponents(["log", "app"])   // "/var/log/app"
```

### Extract directory, base name, and extension

```swift
"/tmp/12345/report.pdf".directoryBaseNameAndExtensionFromPath
// Optional((directory: "/tmp/12345", baseName: "report", extension: "pdf"))

".".directoryBaseNameAndExtensionFromPath         // nil  (resolves to empty)
```

### Split filename into base + extension

```swift
"archive.tar.gz".separateExtension
// (base: "archive.tar", ext: "gz")
```

### Get every intermediate path

```swift
"/a/b/c".intermediaryPaths
// ["/a", "/a/b", "/a/b/c"]
```

### Make a path relative to another

Generates `..` ascent sequences for the remaining base components. Returns `self` when mixing absolute and relative paths.

```swift
"/a/b/c/d".relative(to: "/a/b")                 // "c/d"
"a/b/c".relative(to: "a/b/c/d")                 // ".."
"a/b/x".relative(to: "a/b/c")                   // "../x"
"a".relative(to: "b")                            // "../a"
"/a/b".relative(to: "x/y")                      // "/a/b"  (mixed absolute/relative)
```

### Compare paths (with optional case‑sensitivity)

Comparison uses resolved components, so syntactically different but semantically equal paths match.

```swift
"/Users/Me".samePath(otherPath: "/users/me", caseSensitive: false)  // true
"/Users/Me".samePath(otherPath: "/Users/Me", caseSensitive: true)   // true
"a/b/c".samePath(otherPath: "a/b/x/../c", caseSensitive: true)      // true
```

### Sanitize filenames for NTFS

```swift
"report?:final.txt".safeFilenameForNTFS   // "report.final.txt"
"CON".safeFilenameForNTFS                 // "_CON_"
"file.txt".isSafeFilenameForNTFS          // true
```

---

## API overview

### `[String]` extensions

| Property            | Returns  | Description                                   |
|---------------------|----------|-----------------------------------------------|
| `path`              | `String` | Components joined with `/`                    |
| `backslashPath`     | `String` | Components joined with `\`                    |
| `rootPath`          | `String` | `/` + `path`                                  |
| `rootPathBackslash` | `String` | `\` + `backslashPath`                         |

### `String` extensions

| Member                             | Returns                 | Description                                          |
|------------------------------------|-------------------------|------------------------------------------------------|
| `pathComponents`                   | `[String]`              | Split on `/`, resolve `.` and `..`                   |
| `lastPathComponent`                | `String?`               | Last resolved component, or `nil`                    |
| `removingLastPathComponent`        | `String`                | Path with last component stripped                    |
| `appendingPathComponent(_:)`       | `String`                | Append and resolve against base                      |
| `appendingPathComponents(_:)`      | `String`                | Append multiple components                           |
| `separateExtension`                | `(base: String, ext: String?)` | Split filename at last `.`                    |
| `directoryBaseNameAndExtensionFromPath` | `(directory: String, baseName: String, extension: String)?` | Full decomposition |
| `intermediaryPaths`                | `[String]`              | All intermediate paths                               |
| `relative(to:)`                    | `String`                | Relative path with `..` ascent                       |
| `samePath(otherPath:caseSensitive:)` | `Bool`                | Resolved component‑wise equality                     |

### NTFS safety

| Member                        | Returns | Description                                 |
|-------------------------------|---------|---------------------------------------------|
| `safeFilenameForNTFS`         | `String` | Replace forbidden chars, escape reserved names |
| `isSafeFilenameForNTFS`       | `Bool`   | Check if filename needs no transformation   |

---

## License

MIT © Rui Nelson
