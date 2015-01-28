# vCard Turbo

Keep your organization's contacts up to date by importing contacts
from vCard files located at remote servers.

You get new contacts and updates to existing contacts already on your
phone. _The app never overwrites existing contact records on your
phone._

Save for the permission to access the address book, the app never asks
anything from you. This is a tool for importing lots of contacts and
you don't want to get bothered with questions about which new fields
for which contacts you actually want to import.

The app supports accessing vCard files with http(s), optionally with
basic authentication. The app avoids unnecessary downloading if the
remote vCard file has not been changed since the last check.

There may be multiple sources for remote vCards. The app attempts to
download vCard files from all of them. You can disable individual
sources from import, too.

## Contact update algorithm

After downloading a remote vCard file, the app builds a changeset
from the contact record data inside it.

An imported contact record is considered as new if there's no other
contact with the same name (by comparing records' first and last
names) in the phone's address book. Such a contact gets added to the
address book as is.

A contact record with one matching name is considered a candidate for
possible changes in record fields. The app marks a single-value-field
(such as the job title) for addition if the record has no existing
value for it. For multi-value-fields (such as phone numbers), any
field with nonexisting values gets added. The labels of
multi-value-fields are ignored.

The app ignores imported contact record with multiple matches to
existing address book records.

After building the changesets, the app applies them to the address
book.

The order of vCard sources matters: the app imports contact records by
going through the sources from top to bottom. Contact records from the
later sources might get ignored because a former source filled in the
data already. For example, if the first source has a job title value
for a person, then the app chooses that value and ignores the possible
job title values for the same person from other sources.

## Technical features

* The app utilizes HEAD request to avoid unnecessary downloading of the
  remote file by checking if the Etag or Modified-Since response
  header has changed since the last import.
* The name and URL fields in the vCard source detail view validate the
  input asynchronously, with throttling and switch-latest
  functionality (ensuring that only the response of the last URL
  validation request gets counted in, tackling the problem of
  interleaved responses).
* Nonsensitive user data is stored to NSUserDefaults, JSON encoded.
* Sensitive user data (usernames and passwords, currently) is stored
  to the phone's keychain, JSON encoded.
* The progress bar shown while importing considers download progress
  from each source separately.

## Thanks

The app uses the following open source software, in modified or in
original form:

* [Alamofire](https://github.com/Alamofire/Alamofire) by Mattt
  Thompson
* [KeychainItemWrapper](https://developer.apple.com/library/ios/samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_m.html)
  by Apple
* [Regular Expression for URL validation](https://gist.github.com/dperini/729294)
  by Diego Perini

Thanks to [Reaktor](http://reaktor.fi/) for sponsorship and the
awesome people there for guidance! Tommi Asiala
([@tommi](https://github.com/tommi)) designed the app icon and got
paid with a lunch coupon. :)

## Legal

Copyright © 2015 Tuomas Kareinen.
