import Vapor

struct Event: Content {
    var Event_ID: String
    var Event_Title: String
    var Event_Date: String
    var Event_Time: String
    var Event_Location: String
    var Event_Description: String
    var User_UID: String
    var Event_Attendance: Int?
    var image_base64: String?
}