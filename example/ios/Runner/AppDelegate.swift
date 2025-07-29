import UIKit
import CallKit
import AVFAudio
import PushKit
import WebRTC
import Flutter
import flutter_callkit_incoming
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate  {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        //Setup VOIP
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        //Use if using WebRTC
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false

        // Configure UserNotifications for background notifications
        UNUserNotificationCenter.current().delegate = self

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle notification when app is in background/terminated
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification received in background/terminated state")
        
        let userInfo = response.notification.request.content.userInfo
        handleNotificationData(userInfo)
        
        completionHandler()
    }

    // Handle notification when app is in foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground")
        
        let userInfo = notification.request.content.userInfo
        handleNotificationData(userInfo)
        
        // Don't show notification banner in foreground for VoIP calls
        completionHandler([])
    }

    // Process notification data and show CallKit
    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        print("Processing notification data: \(userInfo)")
        
        // guard let id = userInfo["id"] as? String,
        //       let nameCaller = userInfo["nameCaller"] as? String,
        //       let handle = userInfo["handle"] as? String else {
        //     print("Missing required notification data")
        //     return
        // }
        
        // let isVideo = userInfo["isVideo"] as? Bool ?? false
        // let iconName = userInfo["iconName"] as? String ?? "CallKitLogo"
        // let handleType = userInfo["handleType"] as? String ?? "generic"
        // let audioSessionMode = userInfo["audioSessionMode"] as? String ?? "default"
        // let ringtonePath = userInfo["ringtonePath"] as? String ?? "system_ringtone_default"
        // let avatar = userInfo["avatar"] as? String ?? ""

        // let data = flutter_callkit_incoming.Data(id: id, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        // data.appName = "Ligsim Softphone"
        // data.iconName = iconName
        // data.handleType = handleType
        // data.audioSessionMode = audioSessionMode
        // data.ringtonePath = ringtonePath
        // data.avatar = avatar
        // data.uuid = UUID().uuidString

        // print("Showing CallKit for background notification: \(data.toJSON())")
        // SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
    }

    // Handle remote notification registration failure
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // Handle remote notification received when app is running
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Remote notification received: \(userInfo)")
        
        handleNotificationData(userInfo)
        completionHandler(.newData)
    }

    // Call back from Recent history
    override func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let handleObj = userActivity.handle else {
            return false
        }

        guard let isVideo = userActivity.isVideo else {
            return false
        }
        let objData = handleObj.getDecryptHandle()

        let nameCaller = objData["nameCaller"] as? String ?? ""
        let handle = objData["handle"] as? String ?? ""
        let data = flutter_callkit_incoming.Data(id: UUID().uuidString, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        //set more data...
        //data.nameCaller = nameCaller
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.startCall(data, fromPushKit: true)

        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print(deviceToken)
        //Save deviceToken to your server
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }

    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")
        guard type == .voIP else { return }

        // let id = payload.dictionaryPayload["id"] as? String ?? ""
        // let nameCaller = payload.dictionaryPayload["nameCaller"] as? String ?? ""
        // let handle = payload.dictionaryPayload["handle"] as? String ?? ""
        // let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
        // let iconName = payload.dictionaryPayload["iconName"] as? String ?? "CallKitLogo"
        // let handleType = payload.dictionaryPayload["handleType"] as? String ?? "generic"
        // let audioSessionMode = payload.dictionaryPayload["audioSessionMode"] as? String ?? "default"
        // let ringtonePath = payload.dictionaryPayload["ringtonePath"] as? String ?? "system_ringtone_default"
        // let avatar = payload.dictionaryPayload["avatar"] as? String ?? ""

        // let data = flutter_callkit_incoming.Data(id: id, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        // //set more data
        // //data.extra = ["user": "abc@123", "platform": "ios"]
        // data.appName = "Ligsim Softphone"
        // data.iconName = iconName
        // data.handleType = handleType
        // data.audioSessionMode = audioSessionMode
        // data.ringtonePath = ringtonePath
        // data.avatar = avatar
        // data.uuid = UUID().uuidString

        // print(data.toJSON())
        // SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)

        // //Make sure call completion()
        // DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        //     completion()
        // }
    }


    // Func Call api for Accept
    func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
        let json = ["action": "ACCEPT", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onAccept")
        action.fulfill()
    }

    // Func Call API for Decline
    func onDecline(_ call: Call, _ action: CXEndCallAction) {
        let json = ["action": "DECLINE", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onDecline")
        action.fulfill()
    }

    // Func Call API for End
    func onEnd(_ call: Call, _ action: CXEndCallAction) {
        let json = ["action": "END", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onEnd")
        action.fulfill()
    }

    // Func Call API for TimeOut
    func onTimeOut(_ call: Call) {
        let json = ["action": "TIMEOUT", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onTimeOut")
    }

    // Func Callback Toggle Audio Session
    func didActivateAudioSession(_ audioSession: AVAudioSession) {
        //Use if using WebRTC
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = true
    }

    // Func Callback Toggle Audio Session
    func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
        //Use if using WebRTC
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }
}
