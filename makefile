#
# identify.library
#
# Copyright (C) 2021 Richard "Shred" Koerber
#        http://identify.shredzone.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

SRCP      = src
INCP      = include
LOCP	  = locale
REFP      = reference
DSTP      = distribution
OBJP      = build
RELP      = release
DOCP      = docs

ID_OBJS   = $(OBJP)/ID_Main.o $(OBJP)/ID_Support.o $(OBJP)/ID_Hardware.o \
			$(OBJP)/ID_Locale.o $(OBJP)/ID_Functions.o $(OBJP)/ID_Expansion.o \
			$(OBJP)/ID_Database.o $(OBJP)/ID_Clockfreq.o $(OBJP)/ID_Alerts.o \
			$(OBJP)/ppcgetinfo.o $(OBJP)/ppccpuclock.o \
			$(OBJP)/ID_EndCode.o

ID_OBJS_000 = $(OBJP)/000/ID_Main.o $(OBJP)/000/ID_Support.o $(OBJP)/000/ID_Hardware.o \
			$(OBJP)/000/ID_Locale.o $(OBJP)/000/ID_Functions.o $(OBJP)/000/ID_Expansion.o \
			$(OBJP)/000/ID_Database.o $(OBJP)/000/ID_Clockfreq.o $(OBJP)/000/ID_Alerts.o \
			$(OBJP)/ppcgetinfo.o $(OBJP)/ppccpuclock.o \
			$(OBJP)/ID_EndCode.o

EX_OBJS   = $(OBJP)/EX_Main.o

RI_OBJS   = $(OBJP)/RI_Main.o

AOPTS     = -Fhunk -esc -sc \
			-I $(INCP) -I $(REFP) -I ${AMIGA_NDK}/Include_I/ -I ${AMIGA_INCLUDES} -I ${OBJP}/locale
COPTS     = +aos68k -c99 -lauto -lamiga -cpu=68020 \
			-I${VBCC}/targets/m68k-amigaos/include \
			-I$(REFP) -I${AMIGA_NDK}/Include_H/ -I${AMIGA_INCLUDES} \
			-L=${AMIGA_NDK}/lib/
LOPTS     = -bamigahunk -mrel -s \
			-L ${AMIGA_NDK}/lib/ -l debug -l amiga

.PHONY : all clean source release check pack

all: $(OBJP) \
		$(REFP)/inline/identify_protos.h \
		$(REFP)/proto/identify.h \
		$(OBJP)/locale/ID_Locale.i \
		$(OBJP)/locale/LocaleTools.i \
		$(OBJP)/locale/Identify.ct \
		$(OBJP)/locale/IdentifyTools.ct \
		$(OBJP)/locale/deutsch/Identify.catalog \
		$(OBJP)/locale/deutsch/IdentifyTools.catalog \
		$(OBJP)/locale/italiano/Identify.catalog \
		$(OBJP)/locale/italiano/IdentifyTools.catalog \
		$(OBJP)/identify.library \
		$(OBJP)/identify.library_000 \
		$(OBJP)/rexxidentify.library \
		$(OBJP)/expname.library \
		$(OBJP)/Function $(OBJP)/Guru $(OBJP)/InstallIfy $(OBJP)/ListExp \
		$(OBJP)/ExpansionMUI $(OBJP)/MyExp

clean:
	rm -rf $(OBJP) $(RELP) $(REFP)/inline/identify_protos.h $(REFP)/proto/identify.h

release: clean all
	cp -r $(DSTP) $(RELP)				# Create base structure and static files

	mkdir $(RELP)/IdentifyUsr/Identify/c
	mkdir $(RELP)/IdentifyUsr/Identify/catalogs
	mkdir $(RELP)/IdentifyUsr/Identify/libs

	cp $(OBJP)/Function $(RELP)/IdentifyUsr/Identify/c/					# C
	cp $(OBJP)/Guru $(RELP)/IdentifyUsr/Identify/c/
	cp $(OBJP)/InstallIfy $(RELP)/IdentifyUsr/Identify/c/
	cp $(OBJP)/ListExp $(RELP)/IdentifyUsr/Identify/c/

	cp -r $(OBJP)/locale/deutsch $(RELP)/IdentifyUsr/Identify/catalogs/	# Catalogs
	cp -r $(OBJP)/locale/italiano $(RELP)/IdentifyUsr/Identify/catalogs/

	cp $(DOCP)/Identify-D.guide $(RELP)/IdentifyUsr/Identify/docs/		# Docs
	cp $(DOCP)/Identify-E.guide $(RELP)/IdentifyUsr/Identify/docs/

	cp $(OBJP)/identify.library $(RELP)/IdentifyUsr/Identify/libs/		# Libraries
	cp $(OBJP)/identify.library_000 $(RELP)/IdentifyUsr/Identify/libs/
	cp $(OBJP)/rexxidentify.library $(RELP)/IdentifyUsr/Identify/libs/

	mkdir $(RELP)/IdentifyDev/Identify/catalogs
	mkdir $(RELP)/IdentifyDev/Identify/developer/include

	cp $(OBJP)/locale/Identify.ct $(RELP)/IdentifyDev/Identify/catalogs/	# Translation Files
	cp $(OBJP)/locale/IdentifyTools.ct $(RELP)/IdentifyDev/Identify/catalogs/
	cp $(LOCP)/Identify.cd $(RELP)/IdentifyDev/Identify/catalogs/
	cp $(LOCP)/IdentifyTools.cd $(RELP)/IdentifyDev/Identify/catalogs/

	cp $(DOCP)/Identify-Dev.guide $(RELP)/IdentifyDev/Identify/developer/	# Docs
	cp $(DOCP)/identify.doc $(RELP)/IdentifyDev/Identify/developer/

	cp -r $(REFP)/* $(RELP)/IdentifyDev/Identify/developer/include/			# Includes

	cp $(SRCP)/examples/* $(RELP)/IdentifyDev/Identify/examples/			# Examples
	cp $(OBJP)/ExpansionMUI $(RELP)/IdentifyDev/Identify/examples/
	cp $(OBJP)/MyExp $(RELP)/IdentifyDev/Identify/examples/

	rm -f $(OBJP)/IdentifyUsr.lha							# Package
	cd $(RELP)/IdentifyUsr ; lha c -q1 ../IdentifyUsr.lha *
	cp $(DOCP)/IdentifyUsr.readme $(RELP)/
	rm -f $(OBJP)/IdentifyDev.lha
	cd $(RELP)/IdentifyDev ; lha c -q1 ../IdentifyDev.lha *
	cp $(DOCP)/IdentifyDev.readme $(RELP)/

pack: release
	xdftool $(RELP)/IdentifyUsr.adf pack $(RELP)/IdentifyUsr
	xdftool $(RELP)/IdentifyDev.adf pack $(RELP)/IdentifyDev

check:
	# Check for umlauts and other characters that are not platform neutral.
	# The following command will show the files and lines, and highlight the
	# illegal character. It should be replaced with an escape sequence.
	LC_ALL=C grep -R --color='auto' -P -n "[^\x00-\x7F]" $(SRCP) $(INCP) $(REFP) ; true

$(OBJP):
	mkdir -p $(OBJP)
	mkdir -p $(OBJP)/000
	mkdir -p $(OBJP)/locale
	mkdir -p $(OBJP)/locale/deutsch
	mkdir -p $(OBJP)/locale/italiano

#-- pragmas
$(REFP)/inline/identify_protos.h: $(REFP)/fd/identify_lib.fd $(REFP)/clib/identify_protos.h
	mkdir -p $(REFP)/inline/
	fd2pragma --infile $(REFP)/fd/identify_lib.fd --clib $(REFP)/clib/identify_protos.h \
		--to $(REFP)/inline/ --special 70 --autoheader --comment

$(REFP)/proto/identify.h: $(REFP)/fd/identify_lib.fd $(REFP)/clib/identify_protos.h
	mkdir -p $(REFP)/proto/
	fd2pragma --infile $(REFP)/fd/identify_lib.fd --clib $(REFP)/clib/identify_protos.h \
		--to $(REFP)/proto/ --special 38 --autoheader --comment

#-- locale
$(OBJP)/locale/ID_Locale.i: $(LOCP)/Identify.cd $(INCP)/vbcc_i.sd
	flexcat $< $@=$(INCP)/vbcc_i.sd

$(OBJP)/locale/LocaleTools.i: $(LOCP)/IdentifyTools.cd $(INCP)/vbcc_i.sd
	flexcat $< $@=$(INCP)/vbcc_i.sd

$(OBJP)/locale/%.ct: $(LOCP)/%.cd
	flexcat $< NEWCTFILE $@

$(OBJP)/locale/deutsch/Identify.catalog: $(LOCP)/deutsch/Identify.ct $(LOCP)/Identify.cd
	flexcat NOOPTIM $(LOCP)/Identify.cd $(LOCP)/deutsch/Identify.ct CATALOG $@

$(OBJP)/locale/deutsch/IdentifyTools.catalog: $(LOCP)/deutsch/IdentifyTools.ct $(LOCP)/IdentifyTools.cd
	flexcat NOOPTIM $(LOCP)/IdentifyTools.cd $(LOCP)/deutsch/IdentifyTools.ct CATALOG $@

$(OBJP)/locale/italiano/Identify.catalog: $(LOCP)/italiano/Identify.ct $(LOCP)/Identify.cd
	flexcat NOOPTIM $(LOCP)/Identify.cd $(LOCP)/italiano/Identify.ct CATALOG $@

$(OBJP)/locale/italiano/IdentifyTools.catalog: $(LOCP)/italiano/IdentifyTools.ct $(LOCP)/IdentifyTools.cd
	flexcat NOOPTIM $(LOCP)/IdentifyTools.cd $(LOCP)/italiano/IdentifyTools.ct CATALOG $@

#-- identify.library
$(OBJP)/identify.library: $(ID_OBJS)
	vlink $(LOPTS) -o $@ -s $(ID_OBJS)

$(OBJP)/identify.library_000: $(ID_OBJS_000)
	vlink $(LOPTS) -o $@ -s $(ID_OBJS_000)

$(OBJP)/%.o: $(SRCP)/identify/%.s
	vasmm68k_mot $(AOPTS) -D_MAKE_68020 -L $@.lst -o $@ $<

$(OBJP)/000/%.o: $(SRCP)/identify/%.s
	vasmm68k_mot $(AOPTS) -L $@.lst -o $@ $<

$(OBJP)/%.o: $(SRCP)/identify/ppc/%.s
	vasmppc_std -Fhunk -L $@.lst -o $@ $<

$(OBJP)/%.o: $(SRCP)/identify/ppc/%.c
	vc -c $(COPTS) -o=$@ $<

#-- expname.library
$(OBJP)/expname.library: $(EX_OBJS)
	vlink $(LOPTS) -o $@ -s $(EX_OBJS)

$(OBJP)/%.o: $(SRCP)/expname/%.s
	vasmm68k_mot $(AOPTS) -L $@.lst -o $@ $<

#-- rexxidentify.library
$(OBJP)/rexxidentify.library: $(RI_OBJS)
	vlink $(LOPTS) -o $@ -s $(RI_OBJS)

$(OBJP)/%.o: $(SRCP)/rexxidentify/%.s
	vasmm68k_mot $(AOPTS) -L $@.lst -o $@ $<

#-- tools
$(OBJP)/%: $(SRCP)/tools/%.s
	vasmm68k_mot $(AOPTS) -L $@.lst -o $@.o $<
	vlink $(LOPTS) -o $@ -s $@.o

#-- examples
$(OBJP)/ExpansionMUI: $(SRCP)/examples/ExpansionMUI.c
	vc $(COPTS) -o=$@ $<

$(OBJP)/MyExp: $(SRCP)/examples/MyExp.c
	vc $(COPTS) -o=$@ $<
