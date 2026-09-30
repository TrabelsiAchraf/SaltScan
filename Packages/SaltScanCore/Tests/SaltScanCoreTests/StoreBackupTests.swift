import Foundation
import Testing
@testable import SaltScanCore

@Suite("StoreBackup")
struct StoreBackupTests {
    let root: URL
    let store: URL
    let backup: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("StoreBackupTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        store = root.appendingPathComponent("default.store")
        backup = root.appendingPathComponent("Backups/pre-0.5.0")
    }

    private func write(_ text: String, to url: URL) throws {
        try Data(text.utf8).write(to: url)
    }

    private func read(_ url: URL) throws -> String {
        String(decoding: try Data(contentsOf: url), as: UTF8.self)
    }

    @Test("No store, no backup")
    func missingStore() throws {
        #expect(try StoreBackup.backupIfNeeded(storeURL: store, backupDirectory: backup) == false)
        #expect(!FileManager.default.fileExists(atPath: backup.path))
    }

    @Test("Copies the store and the sidecars that exist")
    func copies() throws {
        try write("main", to: store)
        try write("wal", to: URL(fileURLWithPath: store.path + "-wal"))
        #expect(try StoreBackup.backupIfNeeded(storeURL: store, backupDirectory: backup))
        #expect(try read(backup.appendingPathComponent("default.store")) == "main")
        #expect(try read(backup.appendingPathComponent("default.store-wal")) == "wal")
        #expect(!FileManager.default.fileExists(atPath: backup.appendingPathComponent("default.store-shm").path))
        #expect(try read(store) == "main") // original untouched
    }

    @Test("Never overwrites an existing backup")
    func once() throws {
        try write("v1", to: store)
        try StoreBackup.backupIfNeeded(storeURL: store, backupDirectory: backup)
        try write("v2", to: store)
        #expect(try StoreBackup.backupIfNeeded(storeURL: store, backupDirectory: backup) == false)
        #expect(try read(backup.appendingPathComponent("default.store")) == "v1")
    }

    @Test("Leaves no staging folder behind")
    func noStaging() throws {
        try write("main", to: store)
        try StoreBackup.backupIfNeeded(storeURL: store, backupDirectory: backup)
        let siblings = try FileManager.default.contentsOfDirectory(atPath: backup.deletingLastPathComponent().path)
        #expect(siblings == ["pre-0.5.0"])
    }
}
