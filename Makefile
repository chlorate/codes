FORMAT_INI = awk --file ini.awk
FORMAT_TXTCODE = sed 's/\s\+\#.\+$$//g'

TARGETS = \
	dist/dolphin/WRXE08.ini \
	dist/txtcodes/WR9E.txt \
	dist/txtcodes/WR9P.txt \
	dist/txtcodes/WRXE.txt

.PHONY: build
build: $(TARGETS)

.PHONY: clean
clean:
	rm $(TARGETS)

dist/dolphin/WRXE08.ini: src/mega-man-10/WRXE.ar.txt src/mega-man-10/WRXE.gecko.txt
	echo [ActionReplay] > $@
	$(FORMAT_INI) $< >> $@
	echo >> $@
	echo [Gecko] >> $@
	$(FORMAT_INI) $(word 2, $^) >> $@

dist/txtcodes/WR9E.txt: src/mega-man-9/WR9E.gecko.txt
	echo $(notdir $(basename $@)) > $@
	echo Mega Man 9 >> $@
	echo >> $@
	$(FORMAT_TXTCODE) $< >> $@

dist/txtcodes/WR9P.txt: src/mega-man-9/WR9P.gecko.txt
	echo $(notdir $(basename $@)) > $@
	echo Mega Man 9 >> $@
	echo >> $@
	$(FORMAT_TXTCODE) $< >> $@

dist/txtcodes/WRXE.txt: src/mega-man-10/WRXE.gecko.txt
	echo $(notdir $(basename $@)) > $@
	echo Mega Man 10 >> $@
	echo >> $@
	$(FORMAT_TXTCODE) $< >> $@
