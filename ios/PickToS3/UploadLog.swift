import Foundation
import RealmSwift

class UploadLog: Object {
    dynamic var fromURL = ""
    dynamic var fileName = ""
    dynamic var createdAt = NSDate()
}
