//
//  SceneDelegate.swift
//  MyLocation
//
//  Created by Миляев Максим on 10.04.2022.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    //----------------------------------------------------------------------------------------
    // MARK: - scene life cycle
    //----------------------------------------------------------------------------------------
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let _ = (scene as? UIWindowScene) else { return }
        if let tabViewController = window?.rootViewController as? UITabBarController{
            //firt tab
            var navigationController = tabViewController.viewControllers?[0] as! UINavigationController
            let currentLocationViewController = navigationController.viewControllers.first as! CurrentLocationViewController
            currentLocationViewController.managedObjectContext = managedObjectContext
            
            //second tab
            navigationController = tabViewController.viewControllers?[1] as! UINavigationController
            let locationsTableViewController = navigationController.viewControllers.first as! LocationsTableViewcontroller
            locationsTableViewController.managedObjectContext = managedObjectContext
            
            //third tab
            navigationController = tabViewController.viewControllers?[2] as! UINavigationController
            let mapViewController = navigationController.viewControllers.first as! MapViewcontroller
            mapViewController.managedObjectContext = managedObjectContext
        }

        listenForFatalCoreDataNotifications()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        saveContext()
    }
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyLocation")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    lazy var managedObjectContext = persistentContainer.viewContext

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    //----------------------------------------------------------------------------------------
    // MARK: - Helper methods
    //----------------------------------------------------------------------------------------
    func listenForFatalCoreDataNotifications(){
        NotificationCenter.default.addObserver(forName: dataSaveFailedNotification,
                                               object: nil,
                                               queue: OperationQueue.main) { _ in
            let message = """
            There was a fatal error in the app and it canot be continue.

            Press OK to terminate the app. Sorry for the inconvenience
            """
            let alert = UIAlertController(title: "Internal Error",
                                          message: message,
                                          preferredStyle: .alert)
            let action = UIAlertAction(title: "OK",
                                       style: .default) { _ in
                let exception = NSException(name: .internalInconsistencyException,
                                            reason: "Fatal Core Data error",
                                            userInfo: nil)
                exception.raise()
            }
            alert.addAction(action)
            
            if let tabController = self.window?.rootViewController{
                tabController.present(alert,
                                      animated: true,
                                      completion: nil)
            }
        }
    }
}

