import Dyson

@available(iOS 10.0, *)
@objc(Dyson) class Dyson : CDVPlugin {

    private var hasSubscribedToNotifications = false
    var completedUploadsIds : Set<String>!

    @objc(setEnvironment:)
    func setEnvironment(command: CDVInvokedUrlCommand) {

        self.completedUploadsIds = Set<String>()

        //        UploadManager.sharedInstance.emptyDataBase()

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        if let environment = command.arguments[0] as? String
        {
            UploadManager.sharedInstance.environment = environment
            Logger.sharedInstance.isLoggingEnabled = true

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: "Environment Updated Successfully"
            )
        }else{
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Environment Update Failed"
            )
        }

        if !hasSubscribedToNotifications
        {
            NotificationHelper.sharedInstance.subscribeToPendingUploadsEvent(observer: self, selector: #selector(updateUploadsLeft(_:)))
            NotificationHelper.sharedInstance.subscribeToUploadCompletedEvent(observer: self, selector: #selector(uploadCompleted(_:)))
            NotificationHelper.sharedInstance.subscribeToChangeStatusEvent(observer: self, selector: #selector(changeStatus(_:)))
            NotificationHelper.sharedInstance.subscribeToReachabilityChanged(observer: self, selector: #selector(changeWifiIconColor(_:)))

            self.hasSubscribedToNotifications = true
        }

        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )

    }

    @objc(getPendingUploads:)
    func getPendingUploads(command: CDVInvokedUrlCommand) {

        let pendingUploads = UploadManager.sharedInstance.getTotalPendingUploads()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: pendingUploads)

        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )

    }

    private func getFPRCLifeCyclePropertiesFrom(_ arguments : [String]) -> [String:String]{

        var result = [String:String]()
        var properties = [
                          "fprcCode",                   //0
                          "reservationCodes",           //1
                          "methodName",                 //2
                          "stage",                      //3
                          "messageUniqueId",            //4
                          "jurisdiction"]               //5

        if properties.count == arguments.count {
            for index in 0...properties.count-1 {
                let property = properties[index]
                let argument = arguments[index]
                if argument != "" && argument != "{}" {
                    result[property] = argument
                }
            }

            result["icNumber"] = UploadManager.sharedInstance.icNumber
        }
        else {
            Logger.sharedInstance.logError(error: "Invalid arguments receieved!")
        }

        return result

    }

    @objc(sendFPRCLifeCycleEvent:)
    func sendFPRCLifeCycleEvent(command: CDVInvokedUrlCommand) {

        if let arguments = command.arguments as? [String] {
            let properties = getFPRCLifeCyclePropertiesFrom(arguments)
            Logger.sharedInstance.logInfo(info: "Properties : \(properties)")
            Logger.sharedInstance.logInfo(info: "Properties count : \(properties.count) and position of stage : \(properties.keys.index(of: "stage")?.hashValue)")
            UploadManager.sharedInstance.uploadEventToAnalytics(type: .FPRC_LIFECYCLE, withProperties: properties)
        }

    }

    private func getSplunkLogPropertiesFrom(_ arguments : [String]) -> [String:String]{

        var result = [String:String]()
        var properties = ["name",               //0
            "title",              //1
            "body",               //2
            "status",             //3
            "url",                //4
            "method",             //5
            "messageUniqueId",    //6
            "errorMessage"]       //7

        if properties.count == arguments.count {
            for index in 0...properties.count-1 {
                let property = properties[index]
                let argument = arguments[index]
                if argument != "" && argument != "{}" {
                    result[property] = argument
                }
            }

            result["icNumber"] = UploadManager.sharedInstance.icNumber
        }
        else {
            Logger.sharedInstance.logError(error: "Invalid arguments receieved!")
        }

        return result
    }

    @objc(addLogsToAnalytics:)
    func addLogsToAnalytics(command: CDVInvokedUrlCommand) {

        if let arguments = command.arguments as? [String] {
            let properties = getSplunkLogPropertiesFrom(arguments)
            Logger.sharedInstance.logInfo(info: "Properties : \(properties)")
            UploadManager.sharedInstance.uploadEventToAnalytics(type: .SPLUNK_LOGS, withProperties: properties)
        }

    }

    @objc(getEnrollmentProgress:)
    func getEnrollmentProgress(command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        let isconnectionAvailable = NetworkManager.sharedInstance.isConnectedToNetwork()
        if (isconnectionAvailable){
            let pendingUploads = UploadManager.sharedInstance.getTotalPendingUploads()
            let filesUploaded = UploadManager.sharedInstance.getTotalFilesUploaded()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [pendingUploads,filesUploaded])
        }

        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )

    }

    @objc(getCompleteUploadIds:)
    func getCompleteUploadIds(command: CDVInvokedUrlCommand) {

        var result = ""
        if let arrayOfIdsToCheck = command.arguments as? [String]
        {
            result = UploadManager.sharedInstance.retrieveSentStatusOfEnrollmentsWith(messageIds: arrayOfIdsToCheck)
        }
        Logger.sharedInstance.logInfo(info: "getCompleteUploadIds Sending result : \(result)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }

    @objc(updateIcNumber:)
    func updateIcNumber(command: CDVInvokedUrlCommand) {
        if let icNumber = command.arguments[0] as? String
        {
            Logger.sharedInstance.logInfo(info: "Setting ICNumber : \(icNumber)")
            UploadManager.sharedInstance.update(ICNumber: icNumber)
        }
    }

    @objc(startTransmissionOfUploadsOnLogin:)
    func startTransmissionOfUploadsOnLogin(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            UploadManager.sharedInstance.startUploadingEnrollmentsFromDB(andKeychain: true)
        }
    }

    @objc(startTransmissionOfUploads:)
    func startTransmissionOfUploads(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            UploadManager.sharedInstance.startUploadingEnrollmentsFromDB(andKeychain: false)
        }
    }

    @objc(removeSuccessfulRecordsFromDevice:)
    func removeSuccessfulRecordsFromDevice(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .background).async {
            UploadManager.sharedInstance.removeSuccessfulRecordsFromDevice()
        }
    }

    @objc(startTransmissionOfEnrollmentEntry:)
    func startTransmissionOfEnrollmentEntry(command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        if let enrollmentData = command.arguments[0] as? String,
            let uniqueId = command.arguments[1] as? String,
            let enrollmentIdentifier = command.arguments[2] as? String
        {
            DispatchQueue.global(qos: .background).async {

                let enrollmentEntry = ACPTModel(uniqueMessageID: uniqueId, data: enrollmentData, status: "\(EnrollmentStatusType.SEND_TO_HQ_INITIATED)", enrollmentIdentifier: enrollmentIdentifier, rCount: 0)

                UploadManager.sharedInstance.currentEnrollmentKey = enrollmentIdentifier
                UploadManager.sharedInstance.startTransmissionOfCompleteEnrollment(entry: enrollmentEntry)
                { (error, response) in

                    if(error == nil){
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: uniqueId
                        )
                        Logger.sharedInstance.logInfo(info: "Data Sent Successfully!")
                        Logger.sharedInstance.logInfo(info: "Data received is \(response!)")
                    }
                    else{
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: uniqueId
                        )
                        Logger.sharedInstance.logError(error: "Data Send Failed! : \(error?.localizedDescription)")
                    }

                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: command.callbackId
                    )

                }

            }

        }else{
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Invalid parameters"
            )

            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )

        }

    }

    @objc(startTransmissionOfBlob:)
    func startTransmissionOfBlob(command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        if let enrollmentData = command.arguments[0] as? String,
            let uniqueId = command.arguments[1] as? String,
            let blobFolder = command.arguments[2] as? String,
            let enrollmentIdentifier = command.arguments[3] as? String
        {
            DispatchQueue.global(qos: .background).async {
                let enrollmentEntry = ACPTModel(uniqueMessageID: uniqueId, data: enrollmentData, status: "\(EnrollmentStatusType.SEND_TO_BLOB_INITIATED)", enrollmentIdentifier: enrollmentIdentifier, rCount: 0)

                UploadManager.sharedInstance.currentEnrollmentKey = enrollmentIdentifier
                UploadManager.sharedInstance.startTransmissionOfBlob(entry: enrollmentEntry, blobFolder: blobFolder)
                {
                    (error, response) in

                    if(error == nil){
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: uniqueId
                        )
                        Logger.sharedInstance.logInfo(info: "Blob Sent Successfully!")
                        Logger.sharedInstance.logInfo(info: "Response received is \(response!)")
                    }
                    else{
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: uniqueId
                        )
                        Logger.sharedInstance.logError(error: "Blob Send Failed! : \(String(describing: error?.localizedDescription))")
                    }

                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: command.callbackId
                    )

                }
            }

        }else{
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Invalid parameters"
            )

            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )

        }

    }

    @objc private func updateUploadsLeft(_ notification : NSNotification){
        let pendingUploads = notification.userInfo?["pendingUploads"] as! Int
        let command = CDVPluginHelper.sharedInstance.getJavascriptChangeUpdateCurrentUploadedItemsCommandFor(uploadsLeft: pendingUploads)
        Logger.sharedInstance.logInfo(info: "updateUploadsLeft : \(command)")
        self.commandDelegate.evalJs(command)
    }

    @objc private func uploadCompleted(_ notification : NSNotification){
        let messageId = notification.userInfo?["messageId"] as! String
        //        Logger.sharedInstance.logInfo(info: "uploadCompleted : \(self.completedUploadsIds)")
        self.completedUploadsIds.insert(messageId)
        let command = "window.uploadCompleted();"
        self.commandDelegate.evalJs(command)
    }

    @objc private func changeStatus(_ notification : NSNotification){
        let status = notification.userInfo?["status"] as! Int
        let command = CDVPluginHelper.sharedInstance.getJavascriptChangeStatusCommandFor(status : status)
        Logger.sharedInstance.logInfo(info: "changeStatus : \(command)")
        self.commandDelegate.evalJs(command)
    }

    @objc private func changeWifiIconColor(_ notification : NSNotification){
        let colorStatus = notification.userInfo?["ColorStatus"] as! String
        let command = CDVPluginHelper.sharedInstance.getUpdateWifiIconCommandFor(NetworkStatusColor : colorStatus)
        Logger.sharedInstance.logInfo(info: "changeColorStatus : \(command)")
        self.commandDelegate.evalJs(command)
    }

}

