# Release steps

1. Check that dependencies are up to date: `$ make check-pods`
2. Run automatic tests: `$ make test`
3. Do the manual tests described in `TESTING.md`
4. In `CHANGELOG.md`, rename "Upcoming" section to "$VERSION (prepared)"
5. Increase version and build number in `VCardImport/Source/Info.plist`
6. Git commit:
``` sh
$ git add -p
$ git commit -m "Prepare release $VERSION"
$ git push origin master
```
7. Build and upload app archive to App Store, submit for review
8. Possibly add more features, if so, update `CHANGELOG.md` to have "Upcoming" section at the top
9. …
10. After getting review approved and having the app released, update `CHANGELOG.md`: replace "$VERSION (prepared)" section with "$VERSION / $DATE".
11. Git commit changes in `CHANGELOG.md`, tag the commit that was released earlier:
``` sh
$ git add -p
$ git commit -m "Release $VERSION is available"
$ git tag $VERSION $PREPARE_RELEASE_COMMIT_ID
$ git push --tags origin master
```
