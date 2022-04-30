//
//  Functions.swift
//  MyLocation
//
//  Created by Миляев Максим on 16.04.2022.
//

import Foundation

let applicationDocumentDirectory: URL = {
    let paths = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask)
    print("**** path = \(paths[0])")
    return paths[0]
}()

let dataSaveFailedNotification = Notification.Name(rawValue: "DataSaveFailedNotification")
func fatalCoreDataError(_ error: Error){
    print("*** Fatal error: \(error)")
    NotificationCenter.default.post(name: dataSaveFailedNotification,
                                    object: nil)
}

func afterDelay(sec seconds: Double, run: @escaping () -> Void){
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds,
                                  execute: run)
}
