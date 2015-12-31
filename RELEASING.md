# Releasing

## Testing

### vCard sources

* [Body Corp](https://dl.dropboxusercontent.com/u/1404049/vcards/bodycorp.vcf), containing two person kind of contacts (Arnold Alpha, Bert Beta) and one organization kind of contact (Body Corp)
* [Cold Temp](https://dl.dropboxusercontent.com/u/1404049/vcards/coldtemp.vcf), containing one person kind of contact (Cecil Celcius)

### HTTP proxy

Run HTTP proxy with Basic Auth (username `foo`, password `bar`) to base URL `https://dl.dropboxusercontent.com/u/1404049/`:

``` sh
RPROXY_BASIC_AUTH=foo:bar make rproxy
```

### Tests to do manually

1. Import default sources
2. Add, update, and remove vCard sources
3. Try how GUI reacts to
  * Rotating to different device orientations
  * Text sizes while the app is running (set via Settings → General → Accessibility → Larger Text)
4. Disallow access to Contacts (required for the app's Import action, set via Settings → vCard Turbo → Contacts)
5. Try validations
  * Empty and nonempty text for Name, vCard URL, and Login URL fields
  * Invalid HTTP URLs for vCard and Login URL fields
  * 404 response for nonexisting URL
  * 401 response for basic auth rejection

## Release steps

1. Check dependencies are up to date: `$ make check-pods`
2. Run automatic tests: `$ make test`
3. Do manual tests, described above
4. Update "Upcoming" section in changelog:
``` sh
$EDITOR CHANGELOG.md
git add -p
git commit -m 'Update changelog'
git push origin master
```
5. Build and upload app archive for AppStore, submit for review
6. …
7. After getting review approval, update changelog and tag release. Replace "Upcoming" section with release section in changelog:
``` sh
$EDITOR CHANGELOG.md
git add -p
git commit -m 'Prepare $VERSION release'
git tag $VERSION
git push --tags origin master
```
