var exec = require('cordova/exec');

var PLUGIN_NAME = "Dyson";

var Dyson = {

    generateUUID: function() {
        var d = new Date().getTime();
        var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = (d + Math.random()*16)%16 | 0;
            d = Math.floor(d/16);
            return (c=='x' ? r : (r&0x3|0x8)).toString(16);
        });
        return uuid;
    },

    setEnvironment: function (success,failure,environment) {
        exec(success, failure, PLUGIN_NAME, 'setEnvironment', [environment]);
    },

    startTransmissionOfEnrollmentEntry: function (success,failure,data) {
        var enrollmentData = data.enrollmentData;
        var uniqueId = data.messageId;//this.generateUUID();
        var enrollmentKey = data.enrollmentKey;

        exec(success, failure, PLUGIN_NAME, 'startTransmissionOfEnrollmentEntry', [enrollmentData,uniqueId,enrollmentKey]);
    },

    startTransmissionOfBlob: function (success,failure,data) {
        var enrollmentData = data.enrollmentData;
        var enrollmentKey = data.enrollmentKey;
        var blobContainer = data.blobContainer;
        var uniqueId = !!data.photoName && data.photoName || this.generateUUID();

        exec(success, failure, PLUGIN_NAME, 'startTransmissionOfBlob', [enrollmentData,uniqueId,blobContainer,enrollmentKey]);
    },

    getPendingUploads: function (success,failure) {
        exec(success, failure, PLUGIN_NAME, 'getPendingUploads', []);
    },

    getEnrollmentProgress: function (success,failure) {
        exec(success, failure, PLUGIN_NAME, 'getEnrollmentProgress', []);
    },

    getCompleteUploadIds: function (success,arrayOfIdsToCheck) {
        exec(success, null, PLUGIN_NAME, 'getCompleteUploadIds', arrayOfIdsToCheck);
    },

    startTransmissionOfUploads: function () {
        exec(null, null, PLUGIN_NAME, 'startTransmissionOfUploads', []);
    },

    startTransmissionOfUploadsOnLogin: function () {
        exec(null, null, PLUGIN_NAME, 'startTransmissionOfUploadsOnLogin', []);
    },

    removeSuccessfulRecordsFromDevice: function () {
        exec(null, null, PLUGIN_NAME, 'removeSuccessfulRecordsFromDevice', []);
    },

    getPendingEnrollmentsCountExcludingEnrollmentKey: function(success,enrollmentKey) {
        exec(success, null, PLUGIN_NAME, 'getPendingEnrollmentsCountExcludingEnrollmentKey', [enrollmentKey]);
    },

    updateIcNumber: function(icNumber){
        exec(null, null, PLUGIN_NAME, 'updateIcNumber', [icNumber]);
    },

    addLogsToAnalytics: function(data){
        var name = data.name || '';
        var title = data.title || '';
        var body = data.body || '';
        var status = data.status || '';
        var url = data.url || '';
        var method = data.method || '';
        var messageUniqueId = data.messageUniqueId || '';
        var errorMessage = data.error || '';

        exec(null, null, PLUGIN_NAME, 'addLogsToAnalytics', [name, title, body, status, url, method, messageUniqueId, errorMessage]);
    },

    sendFPRCLifeCycleEvent: function(data){
        var reservationCodes = data.reservationCodes && data.reservationCodes.join() || '';
        var fprcCode = data.fprcCode && data.fprcCode.join() || '';
        var stage = data.stage || '';
        var methodName = data.methodName || '';
        var messageUniqueId = data.messageUniqueId || '';
        var jurisdiction = data.jurisdiction || '';

        // var codes = {"fprcCode":fprcCode, "reservationCodes": reservationCodes};
        // var codesString = JSON.stringify(codes);
        exec(null, null, PLUGIN_NAME, 'sendFPRCLifeCycleEvent', [fprcCode, reservationCodes, methodName, stage, messageUniqueId, jurisdiction]);
    }

};

module.exports = Dyson;