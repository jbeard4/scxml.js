js = $(shell find lib/ -name "*.js")

all : dist/scxml.js dist/scxml.min.js

dist/scxml.js : $(js)
	component build -o dist -n scxml -s scxml

dist/scxml.min.js : dist/scxml.js
	uglifyjs dist/scxml.js > dist/scxml.min.js

get-deps : 
	npm install -g component uglifyjs
	component install

clean :
	rm dist/*

.PHONY : get-deps all clean
