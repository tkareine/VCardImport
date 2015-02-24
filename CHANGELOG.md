# Upcoming

* Show the number of contacts skipped from importing in the table cell
  of the vCard source
* Consider only records from local address book for importing, fixing
  attempts to change read-only records (such as those imported from
  Facebook)

# 1.1.0 / 2015-02-20

New features:

* Add notice to be shown when modifying or adding a new vCard source
* Add new icon with green gradient background
* Set green tint color for UI controls
* Discriminate person and organization contact kinds, allowing updating organization contacts
* Add more fields to check and update for changed contacts:
  - prefix, suffix, and nickname fields
  - instant message and social profile fields
  - contact picture

Bug fixes:

* Abort connection if common name validation fails for server certificate
* Describe server certificate errors in the UI
* Set fixed font size for the toolbar
* Fix showing alert message when address book access is denied
* Align cell contents with separator lines in the table view of vCard sources
* Consider downloaded file without vCard data as an error
* Fixed the toolbar not to hide the contents of the table view of vCard sources
* Fixed small UI layout bugs in vCard source detail view

# 1.0.0 / 2015-02-03

* First release
