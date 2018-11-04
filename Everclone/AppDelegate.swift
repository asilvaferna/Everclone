//
//  AppDelegate.swift
//  Everclone
//
//  Created by Adrián Silva on 31/10/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var coreDataStack = CoreDataStack.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let notebookListViewController = NotebookListViewController(coreDataStack: coreDataStack)
        let navigationController = UINavigationController(rootViewController: notebookListViewController)
        window?.rootViewController = navigationController

        return true
    }
}

