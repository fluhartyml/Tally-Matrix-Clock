//
//  Tally_Matrix_ClockApp.swift
//  Tally Matrix Clock
//
//  Created by Michael Fluharty on 10/16/25.
//

import SwiftUI
import UIKit
import CloudKit

@main
struct Tally_Matrix_ClockApp: App {
    @UIApplicationDelegateAdaptor(TallyAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// REM (roadmap 011/003, 2026 NOV 23): receives the SILENT CloudKit push that says the
// household's settings changed, then reads only the settings record. This replaced
// checking a shared public record every second.
final class TallyAppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if !CloudSettings.isRunningTests {
            application.registerForRemoteNotifications()
        }
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let note = CKNotification(fromRemoteNotificationDictionary: userInfo),
              note.subscriptionID == CloudSettings.settingsSubscriptionID else {
            completionHandler(.noData)
            return
        }
        CloudSettings.shared.fetchSettings { ok in
            completionHandler(ok ? .newData : .failed)
        }
    }
}
