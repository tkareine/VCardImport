DSTROOT ?= .
INSTALL_PATH ?= /build

.PHONY: test clean rproxy

test:
	xcodebuild -scheme VCardImport -target Test -destination 'platform=iOS Simulator,name=iPhone 5s,OS=latest' -destination-timeout 10 test

clean:
	rm -fr build DerivedData

rproxy:
	cd Support && bundle exec ruby rproxy.rb
