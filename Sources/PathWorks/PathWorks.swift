import Foundation

private func resolve(_ component: String, into result: inout [String], isAbsolute: Bool) {
    if component == "." {
        return
    } else if component == ".." {
        if let last = result.last, last != ".." {
            result.removeLast()
        } else if !isAbsolute {
            result.append(component)
        }
    } else {
        result.append(component)
    }
}

public extension [String] {
    /// A relative file system path constructed from path components.
    ///
    /// Joins array elements using Unix path separators ("/") to create a hierarchical file path structure. Empty arrays
    /// produce empty strings.
    ///
    /// - Note: Uses Unix-style separators regardless of platform
    /// - Complexity: O(n) where n is the total character count of all components
    var path: String {
        guard count > 0 else {
            return String()
        }

        return joined(separator: "/")
    }

    /// A Windows-style file system path using backslash separators.
    ///
    /// Creates file paths compatible with Microsoft Windows file systems by joining components with backslash
    /// characters ("\\"). Empty arrays produce empty strings.
    ///
    /// - Note: Primarily useful for Windows compatibility or generating Windows-specific file references
    /// - Complexity: O(n) where n is the total character count of all components
    var backslashPath: String {
        guard count > 0 else {
            return String()
        }

        return joined(separator: "\\")
    }

    /// An absolute file system path with a root separator.
    ///
    /// Creates an absolute path by prepending a leading slash to the relative path representation, indicating the path
    /// starts from the file system root.
    ///
    /// - Complexity: O(n) where n is the total character count of all components
    var rootPath: String {
        "/" + path
    }

    /// An absolute Windows-style path with backslash separators.
    ///
    /// Creates an absolute path using Microsoft's backslash convention by prepending a leading backslash to the
    /// relative backslash path representation.
    ///
    /// - Complexity: O(n) where n is the total character count of all components
    var rootPathBackslash: String {
        "\\" + backslashPath
    }
}

public extension String {
    /// Resolved path components extracted from the string.
    ///
    /// Splits on `/`, filters empty components, and resolves `.` (current directory) and `..` (parent directory)
    /// segments. For absolute paths, `..` cannot escape past root.
    ///
    /// ## Resolution Rules
    /// - `.` components are removed
    /// - `..` removes the preceding component, or is preserved for relative paths with no parent to consume
    /// - `..` is dropped for absolute paths when already at root
    ///
    /// - Complexity: O(n) where n is the length of the path string
    var pathComponents: [String] {
        let isAbsolute = first == "/"
        let raw = self.split(separator: "/", omittingEmptySubsequences: true).map { String($0) }
        var result: [String] = []
        for component in raw {
            resolve(component, into: &result, isAbsolute: isAbsolute)
        }
        return result
    }

    /// The last resolved path component, or `nil` if the path is empty.
    ///
    /// Extracts the final component after `.` and `..` resolution. Typically represents a filename or the deepest
    /// directory name. Returns `nil` for paths that resolve to empty (e.g. `"."`, `"a/.."`).
    var lastPathComponent: String? {
        pathComponents.last
    }

    /// The path with the last resolved component removed.
    ///
    /// Removes the final component after `.` and `..` resolution. Absolute paths remain absolute; relative paths
    /// remain relative. A single-component path produces an empty string (or `/` for absolute paths).
    ///
    /// - Complexity: O(n) where n is the length of the path string
    var removingLastPathComponent: String {
        var pcs = pathComponents

        if !pcs.isEmpty {
            pcs.removeLast()
        }

        return first == "/" ? pcs.rootPath : pcs.path
    }

    /// Appends a path component, resolving `.` and `..` contextually against the base.
    ///
    /// The appended component is parsed and resolved: `..` segments pop components from the base path. For absolute
    /// paths, `..` cannot escape past root.
    ///
    /// - Parameter pc: The path component to append (may contain `/` separators, `.`, and `..`)
    /// - Complexity: O(n + m) where n is the current path length and m is the component length
    func appendingPathComponent(_ pc: String) -> String {
        let isAbsolute = first == "/"
        var comps = pathComponents
        for component in pc.pathComponents {
            resolve(component, into: &comps, isAbsolute: isAbsolute)
        }
        return isAbsolute ? comps.rootPath : comps.path
    }

    /// Appends multiple path components to create a new path.
    ///
    /// Sequentially adds each component from the array to the current path. For absolute paths (beginning with '/'),
    /// the result remains absolute.
    ///
    /// - Parameter pcs: Array of path components to append
    /// - Complexity: O(n × m) where n is the number of components and m is the average component length
    func appendingPathComponents(_ pcs: [String]) -> String {
        var path = self
        for pc in pcs {
            path = path.appendingPathComponent(pc)
        }
        return path
    }

    /// The filename separated into base name and extension.
    ///
    /// Splits the string at the last period (.) to extract the base name and file extension. If no extension exists,
    /// the extension component is `nil`.
    ///
    /// ## Edge Cases
    /// - Files without extensions result in `(originalString, nil)`
    /// - Files starting with a period are treated as having no extension
    ///
    /// - Complexity: O(n) where n is the length of the filename
    var separateExtension: (base: String, ext: String?) {
        var parts = self.split(separator: ".").map { String($0) }

        guard parts.count >= 2 else {
            return (self, nil)
        }

        let ext = parts.removeLast()
        let base = parts.joined(separator: ".")

        return (base, ext)
    }

    /// The path decomposed into directory, base name, and extension components.
    ///
    /// Extracts all three major components of a file path: the containing directory, the base filename, and the file
    /// extension. Returns `nil` if the path resolves to empty (e.g. `"."`).
    ///
    /// - Complexity: O(n) where n is the length of the path string
    var directoryBaseNameAndExtensionFromPath:
        (directory: String, baseName: String, extension: String)? {
        let d = self.removingLastPathComponent

        guard let file = self.lastPathComponent, !file.isEmpty else {
            return nil
        }

        let (b, e) = file.separateExtension

        return (d, b, e ?? "")
    }

    /// All intermediate paths leading to the current path.
    ///
    /// Generates a sequence of progressively deeper paths, starting from the shortest and ending with the full path.
    /// Useful for creating directory hierarchies.
    ///
    /// ## Edge Cases
    /// - Empty strings produce empty arrays
    /// - Single-component paths produce arrays containing only that path
    ///
    /// - Complexity: O(n²) where n is the number of path components
    var intermediaryPaths: [String] {
        guard isEmpty == false else {
            return []
        }

        let isRoot = first == "/"

        let finalPath = isRoot ? pathComponents.rootPath : pathComponents.path

        var paths: [String] = [finalPath]

        var previousPath = pathComponents
        guard !previousPath.isEmpty else {
            return isRoot ? ["/"] : []
        }
        previousPath.removeLast()

        while !previousPath.isEmpty {
            paths.append(isRoot ? previousPath.rootPath : previousPath.path)
            previousPath.removeLast()
        }

        return paths.reversed()
    }

    /// A path relative to the specified base path.
    ///
    /// Computes the relative path by stripping common leading components and generating `..` ascent sequences for the
    /// remaining base components. Returns `self` when mixing absolute and relative paths.
    ///
    /// - Parameter basePath: The base path to compute relativity against
    /// - Complexity: O(n + m) where n and m are the component counts of both paths
    func relative(to basePath: String) -> String {
        let selfIsAbsolute = first == "/"
        let baseIsAbsolute = basePath.first == "/"

        guard selfIsAbsolute == baseIsAbsolute else {
            return self
        }

        let fullPathComps = pathComponents
        let basePathComps = basePath.pathComponents

        var commonCount = 0
        let minCount = min(fullPathComps.count, basePathComps.count)
        while commonCount < minCount && fullPathComps[commonCount] == basePathComps[commonCount] {
            commonCount += 1
        }

        let upCount = basePathComps.count - commonCount
        let remaining = Array(fullPathComps[commonCount...])

        return (Array(repeating: "..", count: upCount) + remaining).path
    }

    /// Determines path equality with configurable case sensitivity.
    ///
    /// Compares two file paths by resolving `.` and `..` segments, then checking component-wise equality. Paths that
    /// resolve to the same components are considered equal regardless of syntactic differences.
    ///
    /// - Parameters:
    ///   - other: The path to compare against
    ///   - caseSensitive: Whether comparison should be case-sensitive
    /// - Complexity: O(n + m) where n and m are the lengths of both paths
    func samePath(otherPath other: String, caseSensitive: Bool) -> Bool {
        let myComps = caseSensitive ? self.pathComponents : self.lowercased().pathComponents
        let otherComps = caseSensitive ? other.pathComponents : other.lowercased().pathComponents

        return myComps == otherComps
    }
}

// MARK: - NTFS

private let point = "."
private let ntfsForbiddenCharacters: [String] = #"<>:"/\|?*"#.map { String($0) }
private let ntfsReservedFilenames = [
    "CON",
    "PRN",
    "AUX",
    "NUL",
    "COM1",
    "COM2",
    "COM3",
    "COM4",
    "COM5",
    "COM6",
    "COM7",
    "COM8",
    "COM9",
    "LPT1",
    "LPT2",
    "LPT3",
    "LPT4",
    "LPT5",
    "LPT6",
    "LPT7",
    "LPT8",
    "LPT9",
]

public extension String {
    /// A filename safe for use on NTFS file systems.
    ///
    /// Converts the string into a valid NTFS filename by replacing forbidden characters with periods and handling
    /// reserved filenames. Trailing whitespace is removed.
    ///
    /// ## NTFS Restrictions
    /// - Forbidden characters: `< > : " / \ | ? *`
    /// - Reserved names: CON, PRN, AUX, NUL, COM1-9, LPT1-9
    ///
    /// ## Transformations
    /// - Reserved filenames are wrapped with underscores: `"CON"` → `"_CON_"`
    /// - Forbidden characters are replaced with periods
    ///
    /// - Complexity: O(n × m) where n is the filename length and m is the number of forbidden characters
    var safeFilenameForNTFS: String {
        guard !isSafeFilenameForNTFS else {
            return self
        }

        var copy = self

        for character in ntfsForbiddenCharacters {
            copy = copy.replacingOccurrences(of: character, with: point)
        }

        while let last = copy.last, last.isWhitespace || last == "." {
            copy = String(copy.dropLast())
        }

        let (baseName, ext) = copy.separateExtension
        if ntfsReservedFilenames.contains(baseName.uppercased()) {
            copy = "_\(baseName)_" + (ext.map { ".\($0)" } ?? "")
        }

        return copy
    }

    var isSafeFilenameForNTFS: Bool {
        if let last, last.isWhitespace || last == "." {
            return false
        }

        for character in ntfsForbiddenCharacters {
            if contains(character) {
                return false
            }
        }

        let (baseName, _) = separateExtension
        if ntfsReservedFilenames.contains(baseName.uppercased()) {
            return false
        }

        return true
    }
}
