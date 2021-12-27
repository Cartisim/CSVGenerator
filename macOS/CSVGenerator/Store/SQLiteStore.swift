//
//  SQLiteStore.swift
//  CSVCreator
//
//  Created by Cole M on 12/25/21.
//  Copyright © 2021 Cole M. All rights reserved.
//

import FluentSQLiteDriver
import Foundation
import FluentKit

enum SQLiteError: Error {
    case notFound
}

fileprivate final class _CSVModel: FluentKit.Model {
    static let schema = "csv"

    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "floor") var floor: String
    @Field(key: "unit") var unit: String
    @Field(key: "address") var address: String
    @Field(key: "district") var district: String
    @Field(key: "phoneNumber") var phoneNumber: String
    
    init() {}

    init(csv: CSVModel, new: Bool) async {
        self.id = csv.id
        $id.exists = !new
        self.name = csv.name ?? ""
        self.floor = csv.floor ?? ""
        self.unit = csv.unit ?? ""
        self.address = csv.address ?? ""
        self.district = csv.district ?? ""
        self.phoneNumber = csv.phoneNumber ?? ""
    }
    func makeContact() throws -> CSVModel {
        CSVModel(id: id!, name: name, floor: floor, unit: unit, address: address, district: district, phoneNumber: phoneNumber)
    }
}

struct CreateContactMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_CSVModel.schema)
            .id()
            .field("name", .string, .required)
            .field("floor", .string)
            .field("unit", .string)
            .field("address", .string)
            .field("district", .string)
            .field("phoneNumber", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_CSVModel.schema).delete()
    }
}

fileprivate func makeSQLiteURL() -> String {
    guard var url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        fatalError()
    }

    url = url.appendingPathComponent("db")

    if FileManager.default.fileExists(atPath: url.path) {
        var excludedFromBackup = URLResourceValues()
        excludedFromBackup.isExcludedFromBackup = true
        try! url.setResourceValues(excludedFromBackup)
    }

    return url.path
}

// TODO: This can become a `struct` when the keychain property is in function scope
final class SQLiteStore: CSVStoreProtocol {
    let databases: Databases
    let database: Database
    var eventLoop: EventLoop { database.eventLoop }

    private init(databases: Databases, database: Database) {
        self.databases = databases
        self.database = database
    }

    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: makeSQLiteURL())
    }

    static func destroy() {
        try? FileManager.default.removeItem(atPath:makeSQLiteURL())
    }

    func destroy() {
        // TODO: Support multiple containers
        Self.destroy()
    }

    public static func create(
        on eventLoop: EventLoop
    ) async throws -> SQLiteStore {
        try await self.create(withConfiguration: .file(makeSQLiteURL()), on: eventLoop).get()
    }
    
    static func create(
        withConfiguration configuration: SQLiteConfiguration,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<SQLiteStore> {
        
        let databases = Databases(
            threadPool: NIOThreadPool(numberOfThreads: 1),
            on: eventLoop
        )
        
        databases.use(.sqlite(configuration), as: .sqlite)
        let logger = Logger(label: "sqlite")
        
        let migrations = Migrations()
        migrations.add(CreateContactMigration())
        
        let migrator = Migrator(databases: databases, migrations: migrations, logger: logger, on: eventLoop)
        return migrator.setupIfNeeded().flatMap {
            migrator.prepareBatch()
        }.recover { _ in }.map {
            return SQLiteStore(
                databases: databases,
                database: databases.database(logger: logger, on: eventLoop)!
            )
        }.flatMapErrorThrowing { error in
            databases.shutdown()
            throw error
        }
    }
    
    func fetchCSVS() async throws -> [CSVModel] {
        try await _CSVModel.query(on: database).all().flatMapEachThrowing {
            try $0.makeContact()
        }.get()
    }
    
    func createCSV(_ csv: CSVModel) async throws {
        try await _CSVModel(csv: csv, new: true).create(on: database).get()
    }
    
    func updateCSV(_ csv: CSVModel) async throws {
        try await _CSVModel(csv: csv, new: false).update(on: database).get()
    }
    
    func removeCSV(_ csv: CSVModel) async throws {
        try await _CSVModel(csv: csv, new: false)
            .delete(on: database).get()
    }

   
    

    deinit {
        DispatchQueue.main.async { [databases] in
            databases.shutdown()
        }
    }
}


protocol CSVStoreProtocol: AnyObject {
    func fetchCSVS() async throws -> [CSVModel]
    func createCSV(_ csv: CSVModel) async throws
    func updateCSV(_ csv: CSVModel) async throws
    func removeCSV(_ csv: CSVModel) async throws
}
