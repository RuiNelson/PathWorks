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

A leading `/` on the appended component is ignored — the component is always treated as relative to the base, and it does not change how `..` resolves. When the base is empty, absoluteness comes from the component instead.

```swift
"/Users".appendingPathComponent("me")            // "/Users/me"
"ab/cd/".appendingPathComponent("ef")            // "ab/cd/ef"
"a/b".appendingPathComponent("..")               // "a"
"a/b".appendingPathComponent("../c")             // "a/c"
"a/b".appendingPathComponent("/../c")            // "a/c"  (leading / ignored)
"/a/b".appendingPathComponent("../../c")         // "/c"
"a/b/".appendingPathComponent("/c/d")            // "a/b/c/d"
"".appendingPathComponent("etc")                 // "etc"
"".appendingPathComponent("/etc")                // "/etc"  (empty base takes / from the component)
"/var".appendingPathComponents(["log", "app"])   // "/var/log/app"
```

### Extract directory, base name, and extension

```swift
"/tmp/12345/report.pdf".directoryBaseNameAndExtensionFromPath
// Optional((directory: "/tmp/12345", baseName: "report", extension: "pdf"))

".".directoryBaseNameAndExtensionFromPath         // nil  (resolves to empty)
```

### Split filename into base + extension

Splits at the last `.` and keeps every other character, so `base + "." + ext` always rebuilds the original name.

```swift
"archive.tar.gz".separateExtension
// (base: "archive.tar", ext: "gz")

".hidden.txt".separateExtension
// (base: ".hidden", ext: "txt")   — the leading dot stays in the base name

".hidden".separateExtension
// (base: ".hidden", ext: nil)     — a lone leading dot is not an extension separator

"abc.".separateExtension
// (base: "abc.", ext: nil)        — a trailing dot is an empty extension, so there is none

"a..b".separateExtension
// (base: "a.", ext: "b")          — interior dots are preserved
```

### Get every intermediate path

```swift
"/a/b/c".intermediaryPaths
// ["/a", "/a/b", "/a/b/c"]
```

### Make a path relative to another

Generates `..` ascent sequences for the remaining base components. Equivalent paths yield `"."`, never an empty string.

`self` is returned unchanged in two cases: when mixing absolute and relative paths, and when the base ascends above the current directory past the common prefix — the correct answer there would require knowing the current directory's own name, which a path string does not carry.

```swift
"/a/b/c/d".relative(to: "/a/b")                 // "c/d"
"a/b/c".relative(to: "a/b/c/d")                 // ".."
"a/b/x".relative(to: "a/b/c")                   // "../x"
"a".relative(to: "b")                            // "../a"
"a/b".relative(to: "a/b")                       // "."  (equivalent paths)
"../a".relative(to: "../b")                     // "../a"  (shared .. prefix is fine)
"/a/b".relative(to: "x/y")                      // "/a/b"  (mixed absolute/relative)
"a".relative(to: "../b")                        // "a"  (base ascends above the current directory)
```

### Compare paths (with optional case‑sensitivity)

Comparison uses resolved components, so syntactically different but semantically equal paths match.

A leading `/` is not part of the comparison, so an absolute path and its relative counterpart compare equal. Check the leading `/` separately when that distinction matters.

```swift
"/Users/Me".samePath(otherPath: "/users/me", caseSensitive: false)  // true
"/Users/Me".samePath(otherPath: "/Users/Me", caseSensitive: true)   // true
"a/b/c".samePath(otherPath: "a/b/x/../c", caseSensitive: true)      // true
"/etc/passwd".samePath(otherPath: "etc/passwd", caseSensitive: true) // true  (leading / not considered)
```

### Sanitize filenames for NTFS

Forbidden characters (`< > : " / \ | ? *` and the control characters U+0000–U+001F) become periods, trailing
whitespace and periods are stripped, and reserved device names are wrapped in underscores. The result is never empty:
a name that sanitizes to nothing falls back to `"_"`.

```swift
"report?:final.txt".safeFilenameForNTFS   // "report.final.txt"
"CON".safeFilenameForNTFS                 // "_CON_"
"CON.tar.gz".safeFilenameForNTFS          // "_CON_.tar.gz"  (matched before the first ".")
"abc.   ".safeFilenameForNTFS             // "abc"           (trailing whitespace and dots removed)
"...".safeFilenameForNTFS                 // "_"             (never returns an empty string)
"".safeFilenameForNTFS                    // "_"

"file.txt".isSafeFilenameForNTFS          // true
"".isSafeFilenameForNTFS                  // false
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
