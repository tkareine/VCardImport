<h1>
  <a href="https://itunes.apple.com/fi/app/vcard-turbo/id961567696">
    <img src="Resources/vt-rounded-60@2x.png?raw=true" width="60" height="60" style="vertical-align: middle; margin-bottom: 0.2em">
  </a>
  vCard Turbo
</h1>

Keep your organization's contacts up to date by importing contacts
from vCard files located at remote servers.

You get new contacts and updates to existing contacts already on your
phone. _The app never overwrites existing contact data on your phone._

Save for granting the permission to access Contacts app (the address
book), the app never asks anything from you. This is a tool for
importing lots of contacts and you don't want to get bothered with
questions about which new fields for which contacts you actually want
to import.

The app supports accessing vCard files with http(s), optionally with
basic authentication. It avoids unnecessary downloading if the remote
vCard file has not been changed since the last check.

There may be multiple sources for remote vCards. The app attempts to
download vCard files from all of them. You can disable individual
sources from importing, too.

*NOTE:* Use the app to import contacts only from sources you
trust. The app is designed to import all contacts from the sources you
specify. You should make a backup of your contacts before use.

<img src="Resources/screenshot-importing-iphone5s.png?raw=true" width="213" height="378" style="border: 1px solid black">
<img src="Resources/screenshot-add-source-iphone5s.png?raw=true" width="213" height="378" style="border: 1px solid black; margin-left: 20px;">

## Contact importing algorithm

After downloading a remote vCard file, the app builds changesets from
the contact record data inside it.

An imported contact record is considered new if there's no other
contact with the same name in the phone's address book (by comparing
records' first and last names). Such a contact gets added to the
address book as is.

A contact record with one matching name in the address book is
considered a candidate for possible changes in record fields. The app
marks a single-value-field (such as the job title) for addition if the
record in the address book has no existing value for it. For
multi-value-fields (such as phone numbers), any field with nonexisting
values in the address book gets marked for addition. The labels of
multi-value-fields are not compared.

If there are multiple name matches for an imported contact record, the
app ignores the record.

After building the changesets, the app applies them to the address
book.

The order of vCard sources matters: the app imports contact records by
going through the sources from top to bottom. Contact records from the
later sources might get ignored because a former source filled in the
data already. For example, if the first source has a job title value
for a person, then the app chooses that value and ignores the possible
job title values for the same person from other sources.

## Technical features

* The app utilizes HEAD request to avoid unnecessary downloading of
  the remote file by checking if the Etag or Last-Modified response
  header has changed since the last import.
* The import job downloads and parses each vCard source asynchronously
  and in parallel (if the system lets it). The application of
  changesets to the address book is done serially.
* The name and URL fields in the vCard source detail view validate the
  input asynchronously, with throttling and switch-latest
  functionality (ensuring that only the response corresponding to the
  last URL validation request gets counted in, tackling the problem of
  interleaved responses).
* Uses [Futures](https://github.com/tkareine/ToyFuture) for handling
  complex asynchronous tasks and their dependencies to each other.
* Stores nonsensitive user data to `NSUserDefaults`, JSON encoded.
* Stores sensitive user data (usernames and passwords, currently) to
  the phone's keychain, JSON encoded.
* The progress bar shown while importing has granularity up to the
  download progress of each individual vCard source. Record changeset
  application counts as well.

## Acknowledgements

The app uses the following open source software, in modified or in
original form:

* [Alamofire](https://github.com/Alamofire/Alamofire) by Mattt
  Thompson
* [KeychainItemWrapper](https://developer.apple.com/library/ios/samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_m.html)
  by Apple Inc.
* [Regular Expression for URL validation](https://gist.github.com/dperini/729294)
  by Diego Perini

Thanks to [Reaktor](http://reaktor.fi/) for sponsorship and the
awesome people there for guidance! Tommi Asiala
([@tommi](https://github.com/tommi)) designed the app icon and got
paid with a lunch coupon. 😊

## Legal

Copyright © 2015 Tuomas Kareinen.
