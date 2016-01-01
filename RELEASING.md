# Releasing

## Testing

### vCard sources

* [Body Corp](https://dl.dropboxusercontent.com/u/1404049/vcards/bodycorp.vcf), containing two person kind of contacts (Arnold Alpha, Bert Beta) and one organization kind of contact (Body Corp)
* [Cold Temp](https://dl.dropboxusercontent.com/u/1404049/vcards/coldtemp.vcf), containing one person kind of contact (Cecil Celcius)

### HTTP proxy

Use the HTTP proxy in `Support/rproxy.rb` to test the app with HTTP basic authentication and HTTP caching. Usage:

``` sh
$ make rproxy
Proxy URL:            https://dl.dropboxusercontent.com/u/1404049/
Basic auth:           uname:passwd
Delete cache headers: false
```

This starts the proxy with default configuration. Use `http://localhost:8080/u/1404049/vcards/bodycorp.vcf` as the vCard URL in the app.

Use environment variables for configuration:

* `RPROXY_URL=$url` for the URL to proxy
* `RPROXY_BASIC_AUTH=$username:$password` for the username and password for HTTP basic auth, use empty value to disable
* `RPROXY_DELETE_CACHE_HEADERS=true|false` to enable deletion of HTTP cache headers from responses

### Tests to do manually

1. Import default sources, see imported contacts in the Contacts app
2. Try HTTP caching effect when importing vCard source again. If the remote supports HTTP cache mechanism, the app shouldn't download the remote file again. If the remote does not support HTTP caching, the app downloads the remote file on every import.
3. Add, update, and remove vCard sources
4. Start import, select vCard source to see its details. Import should proceed in the background.
5. Try how GUI reacts to
  * Rotating to different device orientations
  * Text sizes while the app is running (set via Settings → General → Accessibility → Larger Text)
  * Different devices (iPhone 4S, iPhone 6 Plus, iPad Air 2)
6. Disallow app's access to Contacts (required for the app's Import action, set via Settings → vCard Turbo → Contacts)
7. Try validations
  * Empty and nonempty text for Name, vCard URL, and Login URL fields
  * Invalid HTTP URLs for vCard and Login URL fields
  * 404 response for nonexisting URL
  * 401 response for basic auth rejection

## Release steps

1. Check that dependencies are up to date: `$ make check-pods`
2. Run automatic tests: `$ make test`
3. Do the manual tests described above
4. In `CHANGELOG.md`, rename "Upcoming" section to "$VERSION (prepared)"
5. Increase version and build number in `VCardImport/Source/Info.plist`
6. Git commit:
``` sh
$ git add -p
$ git commit -m "Prepare release $VERSION"
$ git push origin master
```
7. Build and upload app archive to App Store, submit for review
8. …
9. After getting approved review, update `CHANGELOG.md`: replace "$VERSION (prepared)" section with "$VERSION / $DATE".
10. Git commit and tag the release:
``` sh
$ git add -p
$ git commit -m "Release $VERSION"
$ git tag $VERSION
$ git push --tags origin master
```
