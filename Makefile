DSTROOT ?= .
INSTALL_PATH ?= /build

.PHONY: test clean rproxy check-pods

test:
	xcodebuild -scheme VCardImport -target Test -destination 'platform=iOS Simulator,name=iPhone 5s,OS=latest' -destination-timeout 10 test ONLY_ACTIVE_ARCH=YES

clean:
	rm -fr build DerivedData

rproxy:
	cd Support && bundle exec ruby rproxy.rb

check-pods:
	@pod outdated
