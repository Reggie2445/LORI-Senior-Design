import Vapor
@preconcurrency import AWSS3
@preconcurrency import AWSDynamoDB
import AWSClientRuntime
import Foundation

func routes(_ app: Application) throws {

    let bucket = "event-photos-test"
    let tableName = "Events"

    let s3 = try S3Client(region: "us-east-1")
    let dynamo = try DynamoDBClient(region: "us-east-1")

    // CREATE EVENT
    app.post("events") { req async throws -> HTTPStatus in
        let event = try req.content.decode(Event.self)

        var item: [String: DynamoDBClientTypes.AttributeValue] = [
            "Event_ID": .s(event.Event_ID),
            "Event_Title": .s(event.Event_Title),
            "Event_Date": .s(event.Event_Date),
            "Event_Time": .s(event.Event_Time),
            "Event_Location": .s(event.Event_Location),
            "Event_Description": .s(event.Event_Description),
            "Event_Attendance": .l(event.Event_Attendance.map { .s($0) })
        ]

        if let userUID = event.User_UID, !userUID.isEmpty {
            item["User_UID"] = .s(userUID)
        }

        if let base64 = event.image_base64,
           let imageData = Data(base64Encoded: base64) {

            let key = "\(event.Event_ID).jpg"

            try await s3.putObject(
                input: PutObjectInput(
                    body: .data(imageData),
                    bucket: bucket,
                    contentType: "image/jpeg",
                    key: key
                )
            )

            item["Photo_Key"] = .s(key)
        }

        try await dynamo.putItem(
            input: PutItemInput(
                item: item,
                tableName: tableName
            )
        )

        return .created
    }

    // LIST EVENTS
    app.get("events") { req async throws -> [Event] in
        let result = try await dynamo.scan(
            input: ScanInput(tableName: tableName)
        )

        guard let items = result.items else { return [] }

        return items.map { item in
            func stringValue(_ key: String) -> String {
                if case let .s(value)? = item[key] {
                    return value
                }
                return ""
            }

            func listValue(_ key: String) -> [String] {
                if case let .l(values)? = item[key] {
                    return values.compactMap {
                        if case let .s(str) = $0 { return str }
                        return nil
                    }
                }
                return []
            }

            func optionalStringValue(_ key: String) -> String? {
                if case let .s(value)? = item[key] {
                    return value
                }
                return nil
            }

            return Event(
                Event_ID: stringValue("Event_ID"),
                User_UID: optionalStringValue("User_UID"),
                Event_Title: stringValue("Event_Title"),
                Event_Date: stringValue("Event_Date"),
                Event_Time: stringValue("Event_Time"),
                Event_Location: stringValue("Event_Location"),
                Event_Description: stringValue("Event_Description"),
                Event_Attendance: listValue("Event_Attendance"),
                image_base64: nil
            )
        }
    }

    // DELETE EVENT
    app.delete("events", ":id") { req async throws -> HTTPStatus in
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }

        _ = try await dynamo.deleteItem(
            input: DeleteItemInput(
                key: ["Event_ID": .s(id)],
                tableName: tableName
            )
        )

        _ = try? await s3.deleteObject(
            input: DeleteObjectInput(
                bucket: bucket,
                key: "\(id).jpg"
            )
        )

        return .ok
    }
}
