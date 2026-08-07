@testable import PathWorks
import Foundation
import Testing

struct PathWorksTests {
    @Test func stringFilePath() {
        let empty: [String] = []

        #expect(empty.path == "")
        #expect(empty.rootPath == "/")

        let abc = ["a", "b", "c"]

        #expect(abc.path == "a/b/c")
        #expect(abc.rootPath == "/a/b/c")

        #expect("x".pathComponents == ["x"])
        #expect("x".removingLastPathComponent == "")
        #expect("/a/b/c".pathComponents == ["a", "b", "c"])
        #expect("a/b/c".pathComponents == ["a", "b", "c"])
        #expect("/a/b//c".pathComponents == ["a", "b", "c"])
        #expect("/a/b/c/".pathComponents == ["a", "b", "c"])

        #expect("/a/b/c".lastPathComponent == "c")

        #expect("/a/b/c".removingLastPathComponent == "/a/b")
        #expect("/a/b/c/".removingLastPathComponent == "/a/b")
        #expect("a/b/c".removingLastPathComponent == "a/b")
        #expect("".removingLastPathComponent == "")
        #expect("/".removingLastPathComponent == "/")
        #expect("x".removingLastPathComponent == "")
        #expect("/x".removingLastPathComponent == "/")

        #expect("".appendingPathComponent("a") == "a")
        #expect("".appendingPathComponent("a").appendingPathComponent("b") == "a/b")

        #expect("a/b".appendingPathComponent("c") == "a/b/c")
        #expect("/a/b".appendingPathComponent("c") == "/a/b/c")
        #expect("/a/b/".appendingPathComponent("c") == "/a/b/c")

        #expect("a/b/".appendingPathComponent("c/d") == "a/b/c/d")
        #expect("/a/b/".appendingPathComponent("c/d") == "/a/b/c/d")
        #expect("a/b/".appendingPathComponent("/c/d") == "a/b/c/d")

        #expect("x".separateExtension == ("x", nil))
        #expect("x.y".separateExtension == ("x", "y"))
        #expect("x.y.z".separateExtension == ("x.y", "z"))

        #expect("a.z".directoryBaseNameAndExtensionFromPath! == ("", "a", "z"))
        #expect("a/b.c".directoryBaseNameAndExtensionFromPath! == ("a", "b", "c"))
        #expect("a/x/b.c".directoryBaseNameAndExtensionFromPath! == ("a/x", "b", "c"))
        #expect("/x/a/b.c".directoryBaseNameAndExtensionFromPath! == ("/x/a", "b", "c"))
        #expect("/x/a/b.tmp.c".directoryBaseNameAndExtensionFromPath! == ("/x/a", "b.tmp", "c"))
        #expect(".".directoryBaseNameAndExtensionFromPath == nil)

        #expect("".intermediaryPaths == [])
        #expect("aaa".intermediaryPaths == ["aaa"])
        #expect("a/b".intermediaryPaths == ["a", "a/b"])
        #expect("/a/b".intermediaryPaths == ["/a", "/a/b"])
        #expect("a/b/c".intermediaryPaths == ["a", "a/b", "a/b/c"])
        #expect("/a/b/c".intermediaryPaths == ["/a", "/a/b", "/a/b/c"])
        #expect("/a/b/c/".intermediaryPaths == ["/a", "/a/b", "/a/b/c"])
    }
    
    @Test func ntfs() {
        #expect("a:b".safeFilenameForNTFS == "a.b")
        #expect("a/b".safeFilenameForNTFS == "a.b")
        #expect("a\\b".safeFilenameForNTFS == "a.b")
        
        #expect("COM1".safeFilenameForNTFS == "_COM1_")
        #expect("CON.TXT".safeFilenameForNTFS == "_CON_.TXT")
        #expect("abc ".safeFilenameForNTFS == "abc")
        #expect("abc.".safeFilenameForNTFS == "abc")
        #expect("abc.    ".safeFilenameForNTFS == "abc")
    }

    @Test func ntfsAndExtensionEdgeCases() {
        // separateExtension splits at the last period and drops nothing
        #expect("x".separateExtension == ("x", nil))
        #expect("x.y".separateExtension == ("x", "y"))
        #expect("x.y.z".separateExtension == ("x.y", "z"))
        #expect("archive.tar.gz".separateExtension == ("archive.tar", "gz"))
        #expect(".hidden.txt".separateExtension == (".hidden", "txt"))
        #expect(".gitignore.bak".separateExtension == (".gitignore", "bak"))
        #expect("a..b".separateExtension == ("a.", "b"))

        // No extension: no period at all, a lone leading period, or an empty (trailing) extension
        #expect("".separateExtension == ("", nil))
        #expect(".hidden".separateExtension == (".hidden", nil))
        #expect(".gitignore".separateExtension == (".gitignore", nil))
        #expect("a.b.".separateExtension == ("a.b.", nil))
        #expect("abc.".separateExtension == ("abc.", nil))
        #expect("...".separateExtension == ("...", nil))
        #expect(".".separateExtension == (".", nil))

        // base + "." + ext round-trips back to the original filename
        for name in ["x", "x.y", "archive.tar.gz", ".hidden", ".hidden.txt", "a..b", "a.b.", "abc.", "...", "."] {
            let (base, ext) = name.separateExtension
            #expect(base + (ext.map { ".\($0)" } ?? "") == name)
        }

        // Sanitizing never yields an empty filename
        let emptyingInputs = ["", ".", "..", "...", "?", "*?<>", "/", ":", "   ", " . "]
        for input in emptyingInputs {
            #expect(input.safeFilenameForNTFS == "_")
            #expect(!input.safeFilenameForNTFS.isEmpty)
        }

        // The empty string is not a usable filename
        #expect(!"".isSafeFilenameForNTFS)

        // Reserved device names match the segment before the FIRST period; the remainder is preserved
        #expect("CON.tar.gz".safeFilenameForNTFS == "_CON_.tar.gz")
        #expect("con.txt.bak".safeFilenameForNTFS == "_con_.txt.bak")
        #expect("NUL.a.b".safeFilenameForNTFS == "_NUL_.a.b")
        #expect("COM1.x.y".safeFilenameForNTFS == "_COM1_.x.y")
        #expect("aux.foo.bar".safeFilenameForNTFS == "_aux_.foo.bar")
        #expect("CON".safeFilenameForNTFS == "_CON_")
        #expect("CON. ".safeFilenameForNTFS == "_CON_")

        for reserved in ["CON.tar.gz", "con.txt.bak", "NUL.a.b", "COM1.x.y", "aux.foo.bar", "CON", "CON.TXT"] {
            #expect(!reserved.isSafeFilenameForNTFS)
        }

        // A reserved name only matters as a whole leading segment
        #expect("CONSOLE.tar.gz".isSafeFilenameForNTFS)
        #expect("a.CON.gz".isSafeFilenameForNTFS)

        // Control characters (U+0000...U+001F) are forbidden and replaced like any other forbidden character
        for control in ["\u{0000}", "\u{0007}", "\u{001F}"] {
            #expect(!"a\(control)b".isSafeFilenameForNTFS)
            #expect("a\(control)b".safeFilenameForNTFS == "a.b")
        }

        // Safe names are returned untouched
        #expect("file.txt".isSafeFilenameForNTFS)
        #expect("file.txt".safeFilenameForNTFS == "file.txt")
        #expect(".hidden".isSafeFilenameForNTFS)
        #expect(".hidden".safeFilenameForNTFS == ".hidden")

        // Sanitizing is idempotent and always produces a safe filename
        let messyInputs = [
            "",
            "...",
            "   ",
            "a:b",
            "a/b",
            "*?<>",
            "CON",
            "COM1",
            "CON.tar.gz",
            "abc.    ",
            "a\u{0000}b",
        ]
        for input in messyInputs {
            let sanitized = input.safeFilenameForNTFS
            #expect(!sanitized.isEmpty)
            #expect(sanitized.isSafeFilenameForNTFS)
            #expect(sanitized.safeFilenameForNTFS == sanitized)
        }
    }

    @Test func relative() {
        #expect("abc/xyz".relative(to: "abc") == "xyz")
        #expect("abc/xyz/pqr".relative(to: "abc") == "xyz/pqr")
        #expect("abc/xyz/pqr".relative(to: "abc/xyz") == "pqr")
        #expect("abc/xyz/pqr".relative(to: "qwerty") == "../abc/xyz/pqr")
        #expect("/abc/xyz/pqr".relative(to: "qwerty") == "/abc/xyz/pqr")

        #expect("abc/xyz".samePath(otherPath: "abc/xyz", caseSensitive: true))
        #expect("/abc/xyz".samePath(otherPath: "abc/xyz", caseSensitive: true))
        #expect("abc/xyz".samePath(otherPath: "/abc/xyz", caseSensitive: true))
        #expect("ABC/xyz".samePath(otherPath: "abc/XYZ", caseSensitive: false))
    }
    
    @Test func dots() {
        // Single dot
        #expect("a/./b".pathComponents.path == "a/b")
        #expect("a/b/.".pathComponents.path == "a/b")
        #expect("a/.".lastPathComponent == "a")
        #expect(".".pathComponents.path == "")
        #expect("./a/b".pathComponents.path == "a/b")
        #expect("a/././b".pathComponents.path == "a/b")

        // Double dot
        #expect("a/../b".pathComponents.path == "b")
        #expect("a/..".pathComponents.path == "")
        #expect("a/b/..".pathComponents.path == "a")
        #expect("a/b/../../c".pathComponents.path == "c")
        #expect("a/b/c/../../../x".pathComponents.path == "x")
        #expect("a/b/c/../../../../x".pathComponents.path == "../x")
        #expect("a/b/../c/./d".pathComponents.path == "a/c/d")

        // Double dot at start preserved
        #expect("../a".pathComponents.path == "../a")
        #expect("../../a".pathComponents.path == "../../a")
        #expect("..".pathComponents.path == "..")

        // Absolute paths with dots — .. cannot escape root
        #expect("/a/../b".pathComponents == ["b"])
        #expect("/a/b/../..".pathComponents == [])
        #expect("/../a".pathComponents == ["a"])
        #expect("/..".pathComponents == [])
        #expect("/../../a".pathComponents == ["a"])

        // appendingPathComponent resolves .. contextually
        #expect("a/b".appendingPathComponent("..") == "a")
        #expect("a/b".appendingPathComponent("../c") == "a/c")
        #expect("a".appendingPathComponent("..") == "")
        #expect("/a/b".appendingPathComponent("../../c") == "/c")
        #expect("a".appendingPathComponent("../../c") == "../c")

        // Relative with dots
        #expect("a/b/c".relative(to: "a/b/c/d") == "..")
        #expect("a/b/./c".relative(to: "a/b/c/d") == "..")
        #expect("a/b/x".relative(to: "a/b/c") == "../x")
        #expect("a/b/c".relative(to: "a/b/x/..") == "c")
        #expect("a".relative(to: "b") == "../a")
    }

    @Test func pathEdgeCases() {
        // [String].path skips empty components instead of doubling separators
        #expect(["a", "", "b"].path == "a/b")
        #expect(["a", "", "b"].rootPath == "/a/b")
        #expect(["a", "", "b"].backslashPath == "a\\b")
        #expect(["a", "", "b"].rootPathBackslash == "\\a\\b")

        let empty: [String] = []
        #expect(empty.path == "")
        #expect(empty.rootPath == "/")
        #expect(empty.backslashPath == "")
        #expect(empty.rootPathBackslash == "\\")

        #expect([""].path == "")
        #expect([""].rootPath == "/")
        #expect([""].backslashPath == "")
        #expect([""].rootPathBackslash == "\\")

        // A path that survives a round trip keeps every level
        #expect(["a", "", "b"].path.pathComponents == ["a", "b"])

        // appendingPathComponent: against a non-empty base, a leading "/" on the component is ignored entirely — it neither makes the result absolute nor changes how ".." resolves

        #expect("".appendingPathComponent("a") == "a")
        #expect("a/b/".appendingPathComponent("/c/d") == "a/b/c/d")
        #expect("/a/b".appendingPathComponent("../../c") == "/c")
        #expect("a".appendingPathComponent("../../c") == "../c")
        #expect("a/b".appendingPathComponent("..") == "a")
        #expect("a/b".appendingPathComponent("/../c") == "a/c")
        #expect("a/b".appendingPathComponent("/../c") == "a/b".appendingPathComponent("../c"))
        #expect("/a/b".appendingPathComponent("/../../c") == "/c")
        #expect("a/b".appendingPathComponent("/./c") == "a/b/c")

        // appendingPathComponent: an empty base takes its absoluteness from the component
        #expect("".appendingPathComponent("/etc") == "/etc")
        #expect("".appendingPathComponent("/etc/../var") == "/var")
        #expect("".appendingPathComponent("") == "")

        // relative(to:): identical paths yield "." rather than the ambiguous empty string
        #expect("a/b".relative(to: "a/b") == ".")
        #expect("/a/b".relative(to: "/a/b") == ".")
        #expect("a/b/.".relative(to: "a/x/../b") == ".")
        #expect("".relative(to: "") == ".")

        // relative(to:): a base that ascends above the current directory is not representable, so the original path is returned unchanged
        #expect("a".relative(to: "../b") == "a")
        #expect("a/b".relative(to: "../../x") == "a/b")

        // relative(to:): a shared ".." prefix is still a common prefix, so these stay computable
        #expect("../a".relative(to: "../b") == "../a")
        #expect("abc/xyz/pqr".relative(to: "qwerty") == "../abc/xyz/pqr")
        #expect("a/b/c".relative(to: "a/b/x/..") == "c")
        #expect("a/b/c".relative(to: "a/b/c/d") == "..")

        // intermediaryPaths: behavior is unchanged by the single-parse rewrite
        #expect("".intermediaryPaths == [])
        #expect(".".intermediaryPaths == [])
        #expect("/".intermediaryPaths == ["/"])
        #expect("aaa".intermediaryPaths == ["aaa"])
        #expect("a/b".intermediaryPaths == ["a", "a/b"])
        #expect("/a/b/c/".intermediaryPaths == ["/a", "/a/b", "/a/b/c"])
        #expect("../a/b".intermediaryPaths == ["..", "../a", "../a/b"])
        #expect("a/../b".intermediaryPaths == ["b"])

        // samePath ignores the leading "/" — documented, intentional behavior
        #expect("/etc/passwd".samePath(otherPath: "etc/passwd", caseSensitive: true))
    }
}
