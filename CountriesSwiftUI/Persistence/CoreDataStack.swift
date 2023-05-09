//
//  CoreDataStack.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 12.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import CoreData
import Combine

// 프로토콜 정의: CoreData 저장소에서 수행할 수 있는 작업들을 나열합니다.
protocol PersistentStore {
    typealias DBOperation<Result> = (NSManagedObjectContext) throws -> Result
    
    func count<T>(_ fetchRequest: NSFetchRequest<T>) -> AnyPublisher<Int, Error>
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>,
                     map: @escaping (T) throws -> V?) -> AnyPublisher<LazyList<V>, Error>
    func update<Result>(_ operation: @escaping DBOperation<Result>) -> AnyPublisher<Result, Error>
}

// CoreDataStack: PersistentStore 프로토콜을 구현한 구조체입니다.
// 앱의 CoreData 저장소를 관리하고 데이터를 가져오고 업데이트하는 데 사용됩니다.
struct CoreDataStack: PersistentStore {
    
    private let container: NSPersistentContainer
    private let isStoreLoaded = CurrentValueSubject<Bool, Error>(false)
    private let bgQueue = DispatchQueue(label: "coredata")
    
    // 초기화 메서드: 모델 이름 및 경로를 기반으로 NSPersistentContainer를 설정합니다.
    init(directory: FileManager.SearchPathDirectory = .documentDirectory,
         domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
         version vNumber: UInt) {
        log.debug("+")
        
        let version = Version(vNumber)
        container = NSPersistentContainer(name: version.modelName)
        if let url = version.dbFileURL(directory, domainMask) {
            let store = NSPersistentStoreDescription(url: url)
            container.persistentStoreDescriptions = [store]
        }
        // 백그라운드 큐에서 영구 저장소를 로드합니다.
        bgQueue.async { [weak isStoreLoaded, weak container] in
            container?.loadPersistentStores { (storeDescription, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        isStoreLoaded?.send(completion: .failure(error))
                    } else {
                        container?.viewContext.configureAsReadOnlyContext()
                        isStoreLoaded?.value = true
                    }
                }
            }
        }
    }
    
    // 요청된 엔티티의 개수를 가져옵니다.
    func count<T>(_ fetchRequest: NSFetchRequest<T>) -> AnyPublisher<Int, Error> {
        log.debug("+")
        
        return onStoreIsReady
            .flatMap { [weak container] in
                Future<Int, Error> { promise in
                    do {
                        let count = try container?.viewContext.count(for: fetchRequest) ?? 0
                        promise(.success(count))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 요청된 엔티티를 가져온 후, 지정된 매핑 함수를 사용해 변환합니다.
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>,
                     map: @escaping (T) throws -> V?) -> AnyPublisher<LazyList<V>, Error> {
        log.debug("+")
        
        assert(Thread.isMainThread)
        let fetch = Future<LazyList<V>, Error> { [weak container] promise in
            guard let context = container?.viewContext else { return }
            context.performAndWait {
                do {
                    let managedObjects = try context.fetch(fetchRequest)
                    let results = LazyList<V>(count: managedObjects.count,
                                              useCache: true) { [weak context] in
                        let object = managedObjects[$0]
                        let mapped = try map(object)
                        if let mo = object as? NSManagedObject {
                            // Turning object into a fault
                            context?.refresh(mo, mergeChanges: false)
                        }
                        return mapped
                    }
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        return onStoreIsReady
            .flatMap { fetch }
            .eraseToAnyPublisher()
    }
    
    // 지정된 데이터베이스 작업을 사용하여 저장소를 업데이트합니다.
    func update<Result>(_ operation: @escaping DBOperation<Result>) -> AnyPublisher<Result, Error> {
        log.debug("+")
        
        let update = Future<Result, Error> { [weak bgQueue, weak container] promise in
            bgQueue?.async {
                guard let context = container?.newBackgroundContext() else { return }
                context.configureAsUpdateContext()
                context.performAndWait {
                    do {
                        let result = try operation(context)
                        if context.hasChanges {
                            try context.save()
                        }
                        context.reset()
                        promise(.success(result))
                    } catch {
                        context.reset()
                        promise(.failure(error))
                    }
                }
            }
        }
        return onStoreIsReady
            .flatMap { update }
        //          .subscribe(on: bgQueue) // Does not work as stated in the docs. Using `bgQueue.async`
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // 저장소가 준비된 후 수행할 작업을 정의합니다.
    private var onStoreIsReady: AnyPublisher<Void, Error> {
        log.debug("+")
        
        return isStoreLoaded
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: - Versioning

extension CoreDataStack.Version {
    static var actual: UInt { 1 }
}

extension CoreDataStack {
    // CoreDataStack의 버전 관리를 위한 구조체입니다.
    struct Version {
        private let number: UInt
        
        init(_ number: UInt) {
            log.debug("number = \(number)")
            
            self.number = number
        }
        
        // 사용할 CoreData 모델의 이름을 반환합니다.
        var modelName: String {
            return "db_model_v1"
        }
        
        // 지정된 디렉토리 및 도메인 마스크에 해당하는 데이터베이스 파일의 URL을 반환합니다.
        func dbFileURL(_ directory: FileManager.SearchPathDirectory,
                       _ domainMask: FileManager.SearchPathDomainMask) -> URL? {
            log.debug("+")
            
            return FileManager.default
                .urls(for: directory, in: domainMask).first?
                .appendingPathComponent(subpathToDB)
        }
        
        // 데이터베이스 파일의 상대 경로를 반환합니다.
        private var subpathToDB: String {
            return "db.sql"
        }
    }
}
