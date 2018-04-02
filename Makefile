FORMAT_INI = awk --file ini.awk
FORMAT_TXTCODE = sed 's/\s\+\#.\+$$//g'

TARGETS = \
	dist/dolphin/WRXE08.ini \
	dist/txtcodes/WRXE.txt

.PHONY: build
build: $(TARGETS)

.PHONY: clean
clean:
	rm $(TARGETS)

dist/dolphin/WRXE08.ini: src/mega-man-10.ar.txt src/mega-man-10.gecko.txt
	echo [ActionReplay] > $@
	$(FORMAT_INI) $< >> $@
	echo >> $@
	echo [Gecko] >> $@
	$(FORMAT_INI) $(word 2, $^) >> $@

dist/txtcodes/WRXE.txt: src/mega-man-10.gecko.txt
	echo $(notdir $(basename $@)) > $@
	echo Mega Man 10 >> $@
	echo >> $@
	$(FORMAT_TXTCODE) $< >> $@
