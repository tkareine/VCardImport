# Upcoming

New features:

* Hide empty vCard source row placeholders from the main table view
* Describe the dates of vCard sources' last import results in relative
  terms ("Today 3:34 PM")

# 1.3.0 (prepared)

New features:

* Add support for login form authentication with username and password (POST
  request to a login URL)
* Replace vCard source detail view with table based layout; the view is more
  stylish and easier to expand now
* Make toolbar translucent
* Increase timeout for validation throttle a bit, decreasing network traffic

Bug fixes:

* App shouldn't crash when showing vCard source detail view on iOS 9
* Set valid value for HTTP User-Agent header
* Ensure vCard source warning icon shows on large text
* Set scroll bars at proper positions when showing keyboard while adding new
  vCard source and device allows form sheet modal presentation style (on iPads
  and big-screen iPhones in landscape orientation)
* Fix word pluralization if only 1 contact was skipped in vCard last
  import message
* Don't wrap error message if vCard file has no vCard data inside it
* Update button states in main view after swipe to delete vCard source

# 1.2.0 / 2015-03-07

* Show the number of contacts skipped from importing in the table cell of the
  vCard source
* Consider only records from local address book for importing, fixing attempts
  to change read-only records (such as those imported from Facebook)

# 1.1.0 / 2015-02-20

New features:

* Add notice to be shown when modifying or adding a new vCard source
* Add new icon with green gradient background
* Set green tint color for UI controls
* Discriminate person and organization contact kinds, allowing updating
  organization contacts
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
