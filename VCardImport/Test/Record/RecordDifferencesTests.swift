import AddressBook
import UIKit
import XCTest

class RecordDifferencesTests: XCTestCase {
  func testSetsRecordAddition() {
    let newRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsPersonRecordChangesForFieldValues() {
    let oldRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let newRecordHomeAddress = makeAddress(
      street: "Suite 1173",
      zip: "95814",
      city: "Sacramento",
      state: "CA")
    let newInstantMessage = makeInstantMessage(
      service: kABPersonInstantMessageServiceSkype as String,
      username: "bigarnie")
    let newSocialProfile = makeSocialProfile(
      service: kABPersonSocialProfileServiceTwitter as String,
      url: "https://twitter.com/arnie",
      username: "arnie")
    let newRecord = TestRecords.makePerson(
      "Mr.",
      firstName: "Arnold",
      nickName: "Arnie",
      middleName: "Big",
      lastName: "Alpha",
      suffixName: "Senior",
      organization: "State Council",
      jobTitle: "Manager",
      department: "Headquarters",
      phones: [(kABPersonPhoneMainLabel as String, "5551001002")],
      emails: [("Home", "arnold.alpha@example.com")],
      urls: [("Work", "https://exampleinc.com/")],
      addresses: [("Home", newRecordHomeAddress)],
      instantMessages: [(kABPersonInstantMessageServiceSkype as String, newInstantMessage)],
      socialProfiles: [(kABPersonSocialProfileServiceTwitter as String, newSocialProfile)],
      image: loadImage("aa-60"))
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 7)

    let prefixNameChange = singleValueChanges[kABPersonPrefixProperty] as! String!

    XCTAssertEqual(prefixNameChange, "Mr.")

    let nickNameChange = singleValueChanges[kABPersonNicknameProperty] as! String

    XCTAssertEqual(nickNameChange, "Arnie")

    let middleNameChange = singleValueChanges[kABPersonMiddleNameProperty] as! String

    XCTAssertEqual(middleNameChange, "Big")

    let suffixNameChange = singleValueChanges[kABPersonSuffixProperty] as! String

    XCTAssertEqual(suffixNameChange, "Senior")

    let organizationChange = singleValueChanges[kABPersonOrganizationProperty] as! String

    XCTAssertEqual(organizationChange, "State Council")

    let jobTitleChange = singleValueChanges[kABPersonJobTitleProperty] as! String

    XCTAssertEqual(jobTitleChange, "Manager")

    let departmentChange = singleValueChanges[kABPersonDepartmentProperty] as! String

    XCTAssertEqual(departmentChange, "Headquarters")

    let multiValueChanges = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(multiValueChanges.count, 6)

    let phoneChanges = multiValueChanges[kABPersonPhoneProperty]!

    XCTAssertEqual(phoneChanges.count, 1)
    XCTAssertEqual(phoneChanges.first!.0, kABPersonPhoneMainLabel as String)
    XCTAssertEqual(phoneChanges.first!.1 as? String, "5551001002")

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssertEqual(emailChanges.first!.0, "Home")
    XCTAssertEqual(emailChanges.first!.1 as? String, "arnold.alpha@example.com")

    let urlChanges = multiValueChanges[kABPersonURLProperty]!

    XCTAssertEqual(urlChanges.count, 1)
    XCTAssertEqual(urlChanges.first!.0, "Work")
    XCTAssertEqual(urlChanges.first!.1 as? String, "https://exampleinc.com/")

    let addressChanges = multiValueChanges[kABPersonAddressProperty]!

    XCTAssertEqual(addressChanges.count, 1)
    XCTAssertEqual(addressChanges.first!.0, "Home")
    XCTAssertEqual(addressChanges.first!.1 as! [String: NSString], newRecordHomeAddress)

    let instantMessageChanges = multiValueChanges[kABPersonInstantMessageProperty]!

    XCTAssertEqual(instantMessageChanges.count, 1)
    XCTAssertEqual(instantMessageChanges.first!.0, kABPersonInstantMessageServiceSkype as String)
    XCTAssertEqual(instantMessageChanges.first!.1 as! [String: NSString], newInstantMessage)

    let socialProfileChanges = multiValueChanges[kABPersonSocialProfileProperty]!

    XCTAssertEqual(socialProfileChanges.count, 1)
    XCTAssertEqual(socialProfileChanges.first!.0, kABPersonSocialProfileServiceTwitter as String)
    XCTAssertEqual(socialProfileChanges.first!.1 as! [String: NSString], newSocialProfile)

    XCTAssertNotNil(recordDiff.changes.first!.imageChange)
  }

  func testSetsOrganizationRecordChangesForFieldValues() {
    let oldRecord = TestRecords.makeOrganization(name: "Goverment")
    let newRecord = TestRecords.makeOrganization(
      name: "Goverment",
      emails: [("Work", "info@gov.gov")])

    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 0)

    let multiValueChanges = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(multiValueChanges.count, 1)

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssertEqual(emailChanges.first!.0, "Work")
    XCTAssertEqual(emailChanges.first!.1 as? String, "info@gov.gov")
  }

  func testDoesNotSetRecordChangeForNonTrackedFieldValue() {
    let oldRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let newRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    Records.setValue("a note", toSingleValueProperty: kABPersonNoteProperty, of: newRecord)
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDeterminesExistingPersonRecordsByFirstAndLastName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold Alpha"),
      TestRecords.makePerson(lastName: "Arnold Alpha"),
      TestRecords.makePerson(lastName: "Alpha", organization: "Arnold"),
      TestRecords.makePerson(lastName: "Alpha", department: "Arnold"),
      TestRecords.makePerson(middleName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDeterminesExistingOrganizationRecordsByName() {
    let oldRecord = TestRecords.makeOrganization(name: "Goverment")
    let newRecords = [
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "School")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDiscriminatesNamesOfPersonAndOrganizationRecords() {
    let newRecords = [
      TestRecords.makePerson(firstName: "Goverment", lastName: ""),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 2)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForNewRecordsWithEmptyNames() {
    let newRecords = [
      TestRecords.makePerson(firstName: "", lastName: ""),
      TestRecords.makeOrganization(name: "")
    ]
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
    XCTAssertEqual(recordDiff.countSkippedNewRecordsWithDuplicateNames, 0)
    XCTAssertEqual(recordDiff.countSkippedAmbiguousMatchesToExistingRecords, 0)
  }

  func testSkipsRecordAdditionForMultipleNewRecordsHavingSameName() {
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "middle"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
    XCTAssertEqual(recordDiff.countSkippedNewRecordsWithDuplicateNames, 6)
    XCTAssertEqual(recordDiff.countSkippedAmbiguousMatchesToExistingRecords, 0)
  }

  func testSkipsRecordChangeForOldRecordsWithEmptyNames() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "", lastName: ""),
      TestRecords.makeOrganization(name: "")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "", lastName: "", jobTitle: "worker"),
      TestRecords.makeOrganization(name: "", emails: [("Work", "info@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
    XCTAssertEqual(recordDiff.countSkippedNewRecordsWithDuplicateNames, 0)
    XCTAssertEqual(recordDiff.countSkippedAmbiguousMatchesToExistingRecords, 0)
  }

  func testSkipsRecordChangeForMultipleOldRecordsHavingSameName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "worker"),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "info@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
    XCTAssertEqual(recordDiff.countSkippedNewRecordsWithDuplicateNames, 0)
    XCTAssertEqual(recordDiff.countSkippedAmbiguousMatchesToExistingRecords, 6)
  }

  func testSkipsRecordChangeForMultipleNewRecordsHavingSameName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "middle"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter"),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "former@gov.gov")]),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "middle@gov.gov")]),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "latter@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
    XCTAssertEqual(recordDiff.countSkippedNewRecordsWithDuplicateNames, 6)
    XCTAssertEqual(recordDiff.countSkippedAmbiguousMatchesToExistingRecords, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfSingleValueField() {
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager")
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Governor")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingImage() {
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      image: loadImage("aa-60"))
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      image: loadImage("bb-60"))
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfMultiStringValueField() {
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel as String, "5551001001")])
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel as String, "5551001001")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueForMultiStringValueField() {
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel as String, "5551001001")])
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel as String, "5551001002")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonPhoneProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, kABPersonPhoneMainLabel as String)
    XCTAssertEqual(valueChanges.first!.1 as? String, "5551001002")
  }

  func testDoesNotSetRecordChangeForExistingValueOfMultiDictionaryValueField() {
    let addr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", addr)])
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", addr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueOfMultiDictionaryValueField() {
    let oldAddr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let newAddr = makeAddress(street: "Street 2", zip: "00001", city: "City", state: "CA")
    let oldRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", oldAddr)])
    let newRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", newAddr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonAddressProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, "Work")
    XCTAssertEqual(valueChanges.first!.1 as! [String : NSString], newAddr)
  }

  func testDescriptionWithoutChanges() {
    let recordDiff = RecordDifferences(
      additions: [],
      changes: [],
      countSkippedNewRecordsWithDuplicateNames: 0,
      countSkippedAmbiguousMatchesToExistingRecords: 0)
    let description = recordDiff.description

    XCTAssertEqual(description, "Nothing to change")
  }

  func testDescriptionWithChanges() {
    let record = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences(
      additions: [record],
      changes: [],
      countSkippedNewRecordsWithDuplicateNames: 2,
      countSkippedAmbiguousMatchesToExistingRecords: 3)
    let description = recordDiff.description

    XCTAssertEqual(description,
      "1 addition" +
      ", no updates" +
      ", skipped 2 contacts in vCard file due to duplicate names" +
      ", skipped updates to 3 contacts due to ambiguous name matches")
  }

  private func makeAddress(
    street street: String,
    zip: String,
    city: String,
    state: String)
    -> [String: NSString]
  {
    return [
      kABPersonAddressStreetKey as String: street,
      kABPersonAddressZIPKey as String: zip,
      kABPersonAddressCityKey as String: city,
      kABPersonAddressStateKey as String: state
    ]
  }

  private func makeInstantMessage(service service: String, username: String)
    -> [String: NSString]
  {
    return [
      kABPersonInstantMessageServiceKey as String: service,
      kABPersonInstantMessageUsernameKey as String: username
    ]
  }

  private func makeSocialProfile(
    service service: String,
    url: String,
    username: String)
    -> [String: NSString]
  {
    return [
      kABPersonSocialProfileServiceKey as String: service,
      kABPersonSocialProfileURLKey as String: url,
      kABPersonSocialProfileUsernameKey as String: username
    ]
  }

  private func loadImage(filename: String) -> UIImage {
    let path = NSBundle(forClass: RecordDifferencesTests.self).pathForResource(filename, ofType: "png")
    return UIImage(contentsOfFile: path!)!
  }
}
