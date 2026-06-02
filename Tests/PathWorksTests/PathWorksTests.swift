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

        #expect("a.z".directoryBaseNameAndExtensionFromPath == ("", "a", "z"))
        #expect("a/b.c".directoryBaseNameAndExtensionFromPath == ("a", "b", "c"))
        #expect("a/x/b.c".directoryBaseNameAndExtensionFromPath == ("a/x", "b", "c"))
        #expect("/x/a/b.c".directoryBaseNameAndExtensionFromPath == ("/x/a", "b", "c"))
        #expect("/x/a/b.tmp.c".directoryBaseNameAndExtensionFromPath == ("/x/a", "b.tmp", "c"))

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

    @Test func relative() {
        #expect("abc/xyz".relative(to: "abc") == "xyz")
        #expect("abc/xyz/pqr".relative(to: "abc") == "xyz/pqr")
        #expect("abc/xyz/pqr".relative(to: "abc/xyz") == "pqr")
        #expect("abc/xyz/pqr".relative(to: "qwerty") == "abc/xyz/pqr")
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

        // Absolute paths with dots
        #expect("/a/../b".pathComponents.path == "/b")
        #expect("/a/b/../..".pathComponents.path == "/")

        // Relative with dots
        #expect("a/b/c".relative(to: "a/b/c/d") == "..")
        #expect("a/b/./c".relative(to: "a/b/c/d") == "..")
        #expect("a/b/x".relative(to: "a/b/c") == "../x")
        #expect("a/b/x/..".relative(to: "a/b/c") == "c")
        #expect("a".relative(to: "b") == "../a")
    }
}
