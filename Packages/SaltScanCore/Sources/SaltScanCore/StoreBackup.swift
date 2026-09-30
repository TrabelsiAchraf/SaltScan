//
//  StoreBackup.swift
//  SaltScanCore
//
//  One-time copy of the SwiftData store before a version that migrates it.
//  The copy is staged in a temporary folder and moved into place at the end,
//  so an interrupted copy never looks like a finished backup. The original
//  store is only read.
//

import Foundation

public enum StoreBackup {
    /// SQLite sidecar files SwiftData keeps next to the store.
    public static let sidecarSuffixes = ["", "-wal", "-shm"]

    /// Returns true when a backup was made; false when there is no store yet
    /// or a backup already exists (it is never overwritten).
    @discardableResult
    public static func backupIfNeeded(storeURL: URL, backupDirectory: URL, fileManager: FileManager = .default) throws -> Bool {
        guard fileManager.fileExists(atPath: storeURL.path) else { return false }
        guard !fileManager.fileExists(atPath: backupDirectory.path) else { return false }

        let parent = backupDirectory.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let staging = parent.appendingPathComponent(".\(backupDirectory.lastPathComponent)-\(UUID().uuidString)")
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        do {
            for suffix in sidecarSuffixes {
                let source = URL(fileURLWithPath: storeURL.path + suffix)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(at: source, to: staging.appendingPathComponent(source.lastPathComponent))
            }
            try fileManager.moveItem(at: staging, to: backupDirectory)
        } catch {
            // Only our own staging copy is removed, never the store.
            try? fileManager.removeItem(at: staging)
            throw error
        }
        return true
    }
}
