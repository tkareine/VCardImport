import AddressBook
import Foundation
import UIKit

struct TestRecords {
  static func makePerson(
    prefixName: String? = nil,
    firstName: String? = nil,
    nickName: String? = nil,
    middleName: String? = nil,
    lastName: String? = nil,
    suffixName: String? = nil,
    organization: String? = nil,
    jobTitle: String? = nil,
    department: String? = nil,
    phones: [(String, NSString)]? = nil,
    emails: [(String, NSString)]? = nil,
    urls: [(String, NSString)]? = nil,
    addresses: [(String, NSDictionary)]? = nil,
    instantMessages: [(String, NSDictionary)]? = nil,
    socialProfiles: [(String, NSDictionary)]? = nil,
    image: UIImage? = nil)
    -> ABRecord
  {
    let record = ABPersonCreate().takeRetainedValue()
    if let val = prefixName {
      Records.setValue(val, toSingleValueProperty: kABPersonPrefixProperty, of: record)
    }
    if let val = firstName {
      Records.setValue(val, toSingleValueProperty: kABPersonFirstNameProperty, of: record)
    }
    if let val = nickName {
      Records.setValue(val, toSingleValueProperty: kABPersonNicknameProperty, of: record)
    }
    if let val = middleName {
      Records.setValue(val, toSingleValueProperty: kABPersonMiddleNameProperty, of: record)
    }
    if let val = lastName {
      Records.setValue(val, toSingleValueProperty: kABPersonLastNameProperty, of: record)
    }
    if let val = suffixName {
      Records.setValue(val, toSingleValueProperty: kABPersonSuffixProperty, of: record)
    }
    if let val = organization {
      Records.setValue(val, toSingleValueProperty: kABPersonOrganizationProperty, of: record)
    }
    if let val = jobTitle {
      Records.setValue(val, toSingleValueProperty: kABPersonJobTitleProperty, of: record)
    }
    if let val = department {
      Records.setValue(val, toSingleValueProperty: kABPersonDepartmentProperty, of: record)
    }
    if let vals = phones {
      Records.addValues(vals, toMultiValueProperty: kABPersonPhoneProperty, of: record)
    }
    if let vals = emails {
      Records.addValues(vals, toMultiValueProperty: kABPersonEmailProperty, of: record)
    }
    if let vals = urls {
      Records.addValues(vals, toMultiValueProperty: kABPersonURLProperty, of: record)
    }
    if let vals = addresses {
      Records.addValues(vals, toMultiValueProperty: kABPersonAddressProperty, of: record)
    }
    if let vals = instantMessages {
      Records.addValues(vals, toMultiValueProperty: kABPersonInstantMessageProperty, of: record)
    }
    if let vals = socialProfiles {
      Records.addValues(vals, toMultiValueProperty: kABPersonSocialProfileProperty, of: record)
    }
    if let img = image {
      Records.setImage(UIImagePNGRepresentation(img)!, of: record)
    }
    return record
  }

  static func makeOrganization(
    name name: String,
    emails: [(String, NSString)]? = nil)
    -> ABRecord
  {
    let record = ABPersonCreate().takeRetainedValue()
    Records.setValue(kABPersonKindOrganization, toSingleValueProperty: kABPersonKindProperty, of: record)
    Records.setValue(name, toSingleValueProperty: kABPersonOrganizationProperty, of: record)
    if let vals = emails {
      Records.addValues(vals, toMultiValueProperty: kABPersonEmailProperty, of: record)
    }
    return record
  }
}