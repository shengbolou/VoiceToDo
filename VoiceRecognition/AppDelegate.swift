//
//  AppDelegate.swift
//  VoiceRecognition
//
//  Created by Shengbo Lou on 6/11/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import UIKit
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("delegate here")
        if #available(iOS 12.0, *) {
            if let intent = userActivity.interaction?.intent as? INCreateNoteIntent{
                let handler = IntentHandler()
                handler.handle(intent: intent) { (response) in
                    if response.code != .success {
                        print("failed")
                        return
                    }
                }
                return true
            }
            else if userActivity.activityType == NSUserActivity.viewMenuActivityType {
                guard let window = window,
                    let rootViewController = window.rootViewController as? UINavigationController,
                    let toDoTableViewController = rootViewController.viewControllers.first as? ToDoTableViewController else {
                        print("Failed to access OrderHistoryTableViewController.")
                        return false
                }
                toDoTableViewController.performSegue(withIdentifier: "go to create", sender: nil)
                return true
            }
        }
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        guard let window = window,
            let rootViewController = window.rootViewController as? UINavigationController,
            let toDoTableViewController = rootViewController.viewControllers.first as? ToDoTableViewController else {
                print("Failed to access ToDoTableViewController")
                return
        }
        DispatchQueue.main.async{
            do {
                try toDoTableViewController.resultsController.performFetch()
                toDoTableViewController.tableView.reloadData()
            } catch let error  {
                print("error updating tableview: \(error)")
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }



}

