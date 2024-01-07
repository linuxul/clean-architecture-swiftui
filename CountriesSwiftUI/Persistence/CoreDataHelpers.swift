//
//  CoreDataHelpers.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 12.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

// CoreData 도우미 파일입니다.
// 이 파일에는 CoreData와 관련된 유틸리티 및 확장이 포함되어 있습니다.
import CoreData
import Combine

// MARK: - ManagedEntity
// ManagedEntity 프로토콜은 NSFetchRequestResult를 준수하는 타입에 적용됩니다.
protocol ManagedEntity: NSFetchRequestResult { }

extension ManagedEntity where Self: NSManagedObject {
    
    // CoreData 엔티티의 이름을 반환합니다.
    static var entityName: String {
        let nameMO = String(describing: Self.self)
        let suffixIndex = nameMO.index(nameMO.endIndex, offsetBy: -2)
        return String(nameMO[..<suffixIndex])
    }
    
    // 지정된 컨텍스트에서 새로운 인스턴스를 삽입하고 반환합니다.
    static func insertNew(in context: NSManagedObjectContext) -> Self? {
        log.debug("context = \(context)")
        
        return NSEntityDescription
            .insertNewObject(forEntityName: entityName, into: context) as? Self
    }
    
    // 해당 엔티티의 새로운 FetchRequest를 생성합니다.
    static func newFetchRequest() -> NSFetchRequest<Self> {
        log.verbose("+")
        
        return .init(entityName: entityName)
    }
}

// MARK: - NSManagedObjectContext
// NSManagedObjectContext의 도움이 되는 확장입니다.
extension NSManagedObjectContext {
    
    // 읽기 전용 컨텍스트로 설정하도록 NSManagedObjectContext를 구성합니다.
    func configureAsReadOnlyContext() {
        log.verbose("+")
        
        automaticallyMergesChangesFromParent = true
        mergePolicy = NSRollbackMergePolicy
        undoManager = nil
        shouldDeleteInaccessibleFaults = true
    }
    
    // 업데이트 컨텍스트로 설정하도록 NSManagedObjectContext를 구성합니다.
    func configureAsUpdateContext() {
        log.verbose("+")
        
        mergePolicy = NSOverwriteMergePolicy
        undoManager = nil
    }
}

// MARK: - Misc
// NSSet의 확장입니다. NSSet을 특정 타입의 배열로 변환하는 기능을 제공합니다.
extension NSSet {
    func toArray<T>(of type: T.Type) -> [T] {
        allObjects.compactMap { $0 as? T }
    }
}
