import Foundation

private func resolve(_ component: String, into result: inout [String], isAbsolute: Bool) {
    if component == "." {
        return
    }
    else if component == ".." {
        if let last = result.last, last != ".." {
            result.removeLast()
        }
        else if !isAbsolute {
            result.append(component)
        }
    }
    else {
        result.append(component)
    }
}

public extension [String] {
    /// A relative file system path constructed from path components.
    ///
    /// Joins array elements using Unix path separators ("/") to create a hierarchical file path structure. Empty arrays
    /// produce empty strings.
    ///
    /// Empty components are skipped, so no separator is ever doubled: `["a", "", "b"].path` is `"a/b"`, not `"a//b"`.
    ///
    /// - Note: Uses Unix-style separators regardless of platform
    /// - Complexity: O(n) where n is the total character count of all components
    var path: String {
        guard count > 0 else {
            return String()
        }

        return filter { !$0.isEmpty }.joined(separator: "/")
    }

    /// A Windows-style file system path using backslash separators.
    ///
    /// Creates file paths compatible with Microsoft Windows file systems by joining components with backslash
    /// characters ("\\"). Empty arrays produce empty strings.
    ///
    /// Empty components are skipped, so no separator is ever doubled: `["a", "", "b"].backslashPath` is `"a\\b"`.
    ///
    /// - Note: Primarily useful for Windows compatibility or generating Windows-specific file references
    /// - Complexity: O(n) where n is the total character count of all components
    var backslashPath: String {
        guard count > 0 else {
            return String()
        }

        return filter { !$0.isEmpty }.joined(separator: "\\")
    }

    /// An absolute file system path with a root separator.
    ///
    /// Creates an absolute path by prepending a leading slash to the relative path representation, indicating the path
    /// starts from the file system root.
    ///
    /// Empty components are skipped, as they are for ``path``. An array with no non-empty components yields `"/"`.
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
    /// Empty components are skipped, as they are for ``backslashPath``. An array with no non-empty components yields
    /// `"\\"`.
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
    /// Removes the final component after `.` and `..` resolution. Absolute paths remain absolute; relative paths remain
    /// relative. A single-component path produces an empty string (or `/` for absolute paths).
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
    /// The appended component is split on `/` and each segment is resolved against the base: `..` segments pop
    /// components from the base path. For absolute paths, `..` cannot escape past root.
    ///
    /// ## Edge Cases
    /// - A leading `/` on `pc` is ignored: `pc` is always treated as relative to the base, so
    ///   `"a/b".appendingPathComponent("/../c")` is `"a/c"`, exactly as `"../c"` would be
    /// - When the base is empty, absoluteness is taken from `pc` instead, so `"".appendingPathComponent("/etc")` is
    /// `"/etc"` while `"".appendingPathComponent("etc")` is `"etc"`
    ///
    /// - Parameter pc: The path component to append (may contain `/` separators, `.`, and `..`)
    /// - Complexity: O(n + m) where n is the current path length and m is the component length
    func appendingPathComponent(_ pc: String) -> String {
        let isAbsolute = isEmpty ? pc.first == "/" : first == "/"
        var comps = pathComponents
        for component in pc.split(separator: "/", omittingEmptySubsequences: true) {
            resolve(String(component), into: &comps, isAbsolute: isAbsolute)
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
    /// Splits the string at the last period (.) to extract the base name and file extension. Every other character is
    /// preserved verbatim, so `base + "." + ext` always reconstructs the original string. If no extension exists, the
    /// extension component is `nil`.
    ///
    /// ## Edge Cases
    /// - Files without a period result in `(originalString, nil)`
    /// - Files starting with a period are treated as having no extension: `".hidden"` → `(".hidden", nil)`
    /// - A trailing period is an empty extension, not an extension: `"abc."` → `("abc.", nil)`
    /// - Interior periods are kept in the base name: `"a..b"` → `("a.", "b")`
    ///
    /// - Complexity: O(n) where n is the length of the filename
    var separateExtension: (base: String, ext: String?) {
        guard let separator = lastIndex(of: ".") else {
            return (self, nil)
        }

        let extensionStart = index(after: separator)

        // A leading period marks a hidden file and a trailing period yields an empty extension; neither is one.
        guard separator != startIndex, extensionStart != endIndex else {
            return (self, nil)
        }

        return (String(self[startIndex ..< separator]), String(self[extensionStart...]))
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
    /// - Paths that resolve to nothing produce empty arrays (e.g. `"."`, `"a/.."`)
    /// - A root-only path produces `["/"]`, which is not a directory a caller can create
    /// - Relative paths that ascend above the current directory keep their `..` prefix, so entries look like
    ///   `["..", "../a"]`; callers that feed this list to a directory-creation routine must be prepared for
    ///   `..`-prefixed and root entries
    ///
    /// - Complexity: O(n²) where n is the number of path components
    var intermediaryPaths: [String] {
        guard isEmpty == false else {
            return []
        }

        let isRoot = first == "/"
        let comps = pathComponents

        guard !comps.isEmpty else {
            return isRoot ? ["/"] : []
        }

        var paths: [String] = [isRoot ? comps.rootPath : comps.path]

        var previousPath = comps
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
    /// ## Edge Cases
    /// - When the two paths are equivalent the result is `"."`, never the empty string, so the return value is always a
    /// usable relative path
    /// - Returns `self` unchanged when the base ascends above the current directory past the common prefix — i.e. when
    /// the base components left after the common prefix still contain `..`, as in `"a".relative(to: "../b")`. The true
    /// answer would require knowing the current directory's own name, which a path string does not carry
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

        let ascent = basePathComps[commonCount...]

        guard !ascent.contains("..") else {
            return self
        }

        let remaining = Array(fullPathComps[commonCount...])
        let relativePath = (Array(repeating: "..", count: ascent.count) + remaining).path

        return relativePath.isEmpty ? "." : relativePath
    }

    /// Determines path equality with configurable case sensitivity.
    ///
    /// Compares two file paths by resolving `.` and `..` segments, then checking component-wise equality. Paths that
    /// resolve to the same components are considered equal regardless of syntactic differences.
    ///
    /// ## Edge Cases
    /// - A leading `/` is not part of the comparison, so an absolute path and its relative counterpart compare equal:
    ///   `"/etc/passwd".samePath(otherPath: "etc/passwd", caseSensitive: true)` is `true`. Check the leading `/`
    ///   separately when the distinction matters
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

private let point: Character = "."
private let space: Character = " "
/// Forbidden scalars for NTFS: `< > : " / \ | ? *` plus controls U+0000...U+001F.
/// Backed by `Foundation.CharacterSet` (bitmap lookup) instead of a `Set<Character>`.
private let ntfsForbiddenCharacterSet: CharacterSet = {
    var set = CharacterSet(charactersIn: "<>:\"/\\|?*")
    set.formUnion(CharacterSet(charactersIn: Unicode.Scalar(0)! ... Unicode.Scalar(0x1F)!))
    return set
}()

/// The scalar written in place of every forbidden scalar when sanitizing.
private let ntfsDotScalar = Unicode.Scalar(0x2E)!
/// The stand-in used when sanitizing removes every character of a filename.
private let ntfsPlaceholderFilename = "_"
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

/// Maximum filename length on NTFS: 255 UTF-16 code units (`NTFS_MAX_NAME_LEN`).
private let ntfsMaxFilenameLengthUTF16 = 255

/// Whether NTFS rejects `scalar`: either a forbidden literal or a control character in U+0000...U+001F.
private func isForbiddenForNTFS(_ scalar: Unicode.Scalar) -> Bool {
    ntfsForbiddenCharacterSet.contains(scalar)
}

/// Whether the segment before the first period of `filename` names a reserved NTFS device.
private func isNTFSReservedDeviceName(_ filename: Substring) -> Bool {
    ntfsReservedFilenames.contains(filename.uppercased())
}

/// The longest prefix of `string` fitting in `limit` UTF-16 code units, never splitting a `Character`.
private func truncateForNTFSLength(_ string: String, limit: Int = ntfsMaxFilenameLengthUTF16) -> String {
    guard string.utf16.count > limit else {
        return string
    }

    var result = String()
    result.reserveCapacity(min(string.count, limit))

    var used = 0
    for character in string {
        let width = character.unicodeScalars.reduce(0) { $0 + ($1.value >= 0x10000 ? 2 : 1) }
        if used + width > limit {
            break
        }
        result.append(character)
        used += width
    }

    return result
}

public extension String {
    /// A filename safe for use on NTFS file systems.
    ///
    /// Converts the string into a valid NTFS filename by replacing forbidden characters with periods and escaping
    /// reserved device names. The result is never empty.
    ///
    /// ## NTFS Restrictions
    /// - Forbidden characters: `< > : " / \ | ? *`
    /// - Forbidden control characters: U+0000 through U+001F
    /// - Reserved names: CON, PRN, AUX, NUL, COM1-9, LPT1-9
    /// - Names may not end in a space (U+0020) or a period (U+002E)
    ///
    /// ## Transformations
    /// - Forbidden characters, control characters included, are replaced with periods
    /// - Trailing spaces and trailing periods are removed: `"abc.   "` → `"abc"`
    /// - Reserved device names are wrapped with underscores: `"CON"` → `"_CON_"`
    /// - Only the segment before the *first* period is matched and wrapped: `"CON.tar.gz"` → `"_CON_.tar.gz"`
    /// - A name that sanitizes to nothing, or the empty string, falls back to `"_"`: `"..."` → `"_"`
    ///
    /// - Complexity: O(n) where n is the filename length
    var safeFilenameForNTFS: String {
        guard !isSafeFilenameForNTFS else {
            return self
        }

        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            scalars.append(isForbiddenForNTFS(scalar) ? ntfsDotScalar : scalar)
        }

        var copy = String(scalars)

        while let last = copy.last, last == space || last == point {
            copy = String(copy.dropLast())
        }

        guard !copy.isEmpty else {
            return ntfsPlaceholderFilename
        }

        let deviceName = copy.prefix { $0 != point }
        if isNTFSReservedDeviceName(deviceName) {
            copy = "_\(deviceName)_\(copy.dropFirst(deviceName.count))"
        }

        return copy
    }

    /// A Boolean value indicating whether the string is already a valid NTFS filename.
    ///
    /// Returns `true` only when ``safeFilenameForNTFS`` would leave the string untouched: it is not empty, contains no
    /// forbidden or control characters, does not end in a space or a period, and the segment before its first period
    /// is not a reserved device name.
    ///
    /// - Note: The empty string is never safe, since a filename needs at least one character.
    /// - Complexity: O(n) where n is the filename length
    var isSafeFilenameForNTFS: Bool {
        guard let last else {
            return false
        }

        if last == space || last == point {
            return false
        }

        if rangeOfCharacter(from: ntfsForbiddenCharacterSet) != nil {
            return false
        }

        return !isNTFSReservedDeviceName(prefix { $0 != point })
    }

    /// A Boolean value indicating whether the string is a valid NTFS filename including the length limit.
    ///
    /// Returns `true` only when ``isSafeFilenameForNTFS`` is `true` and the name fits in 255 UTF-16 code units
    /// (`NTFS_MAX_NAME_LEN`).
    ///
    /// - Complexity: O(n) where n is the filename length
    var isSafeFilenameForNTFSIncludingLength: Bool {
        guard isSafeFilenameForNTFS else {
            return false
        }

        return utf16.count <= ntfsMaxFilenameLengthUTF16
    }

    /// A filename safe for use on NTFS file systems, including the length limit.
    ///
    /// Starts from ``safeFilenameForNTFS`` and, only when it exceeds 255 UTF-16 code units, truncates it on a
    /// `Character` boundary so no grapheme (and therefore no surrogate pair) is split. A cut that exposes trailing
    /// spaces or periods trims them, and an empty result falls back to `"_"`. The result always satisfies
    /// ``isSafeFilenameForNTFSIncludingLength`` and the function is idempotent.
    ///
    /// - Complexity: O(n) where n is the filename length
    var safeNameForNTFSIncludingLength: String {
        let safe = safeFilenameForNTFS

        guard safe.utf16.count > ntfsMaxFilenameLengthUTF16 else {
            return safe
        }

        var truncated = truncateForNTFSLength(safe)

        while let last = truncated.last, last == space || last == point {
            truncated.removeLast()
        }

        guard !truncated.isEmpty else {
            return ntfsPlaceholderFilename
        }

        // Truncation keeps the leading device segment, so a 255-long result cannot turn reserved. Re-validate
        // defensively: wrapping would add 2 units and could exceed the limit again.
        let resanitized = truncated.safeFilenameForNTFS
        guard resanitized.utf16.count > ntfsMaxFilenameLengthUTF16 else {
            return resanitized
        }

        var refitted = truncateForNTFSLength(resanitized)

        while let last = refitted.last, last == space || last == point {
            refitted.removeLast()
        }

        return refitted.isEmpty ? ntfsPlaceholderFilename : refitted
    }
}
