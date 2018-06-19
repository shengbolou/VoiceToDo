//
//  CoreDataStack.swift
//  VoiceRecognition
//
//  Created by Shengbo Lou on 6/11/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import Foundation
import CoreData


class CoreDataStack{
//    private static var container: NSPersistentContainer{
//        let container = NSPersistentContainer(name: "Todos")
//        container.loadPersistentStores { (description, error) in
//            guard error==nil else{
//                print("Error: \(error!)")
//                return
//            }
//        }
//
//        return container
//    }
    
    private static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Todos")

        var persistentStoreDescriptions: NSPersistentStoreDescription

        let storeUrl =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.apple-samplecode.SoupChef74PB88HF2B")!.appendingPathComponent("todo.sqlite")


        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = storeUrl

        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url:  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.apple-samplecode.SoupChef74PB88HF2B")!.appendingPathComponent("todo.sqlite"))]

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private static var managedContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    static var resultsController: NSFetchedResultsController<Todo>!{
        let request: NSFetchRequest<Todo> = Todo.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return resultsController
    }
    
    
}

