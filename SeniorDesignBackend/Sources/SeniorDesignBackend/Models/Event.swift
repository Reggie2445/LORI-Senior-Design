import Vapor

struct Event: Content {
    var Event_ID: String
    var Event_Title: String
    var Event_Date: String
    var Event_Time: String
    var Event_Location: String
    var Event_Description: String
    var Event_Attendance: [String]
    var image_base64: String?
}