.PHONY:
ZIPFILE=ChromeCBIWeatherApp.zip

.PHONY: chrome
chrome:
	cd chrome; zip -r $(ZIPFILE) *; mv $(ZIPFILE) ..;

.PHONY: clean
clean:
	rm $(ZIPFILE)

