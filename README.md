# identify.library

Identify is a shared Amiga library that helps identifying all kind of system parameters.

The source code was closed, like almost all of my Amiga projects. I have now reviewed and reformatted the files, translated the comments from German to English, and made the project compilable on Linux (and probably other targets) using vbcc. The source is now open to everyone for contributing, studying, archiving, or just enjoying the good old Amiga times.

## Features

* Identifies expansion card names, alerts, and function call names
* Gives information about your Amiga model, CPU, OS version, available memory, chipset, and much more...
* Supports from AmigaOS 2.0 up to the latest AmigaOS 3.2
* The expansion database contains 356 manufacturers and 498 boards
* Distinguishes between most GVP and Phase5 boards with unique ID
* Tries to give at least a hint if the board name is not known yet
* Fully FPGA, DraCo, and PowerPC compatible
* Supports PowerUp and WarpOS
* The library is fully localized (catalogs included: Deutsch)
* Use the features in ARexx, with the included rexxidentify.library
* English and German documentation
* LGPLv3 licensed, open source
* Source Code available at [GitHub](https://github.com/shred/identify)

## Frequently Asked Questions

If you have questions about identify, maybe you will find answers [here](docs/faq.md).

## Building from Source

This project is mainly made to be build on Linux machines. However, with a few modifications it can also be built on AmigaOS and other operating systems.

Requirements:

* [GNU make](http://www.gnu.org/software/make/) or another compatible make tool
* [vbcc](http://www.compilers.de/vbcc.html)
* [fd2pragma](https://github.com/adtools/fd2pragma)
* [FlexCat](https://github.com/adtools/flexcat/releases/tag/2.18)
* [AmigaOS NDK 3.2](https://www.hyperion-entertainment.com/index.php/downloads?view=files&parent=40), unpacked on your build machine
* [MUI](http://sasg.com/mui/download.html) by Stefan Stuntz, includes unpacked on your build machine
* [lha](https://github.com/jca02266/lha)

Set the `AMIGA_NDK` env variable to the location of the unpacked `NDK3.2` directory on your build machine. Also set `AMIGA_INCLUDES` to the location of 3rd party include files, where the MUI includes can be found.

Then just invoke `make` to build the project. The compiled project can be found in the `build` directory. `make release` will compile a release version in the `release` directory.

Today's standard encoding is UTF-8. Unfortunately AmigaOS does not support this encoding, so the files in this project have different encodings depending on their purpose. The assembler and C files must use plain ASCII encoding, so they can be edited on Linux and Amiga without encoding problems. For special characters in strings, always use escape sequences. Do not use special characters in comments. `make check` will test if these files contain illegal characters. All purely Amiga-related files (like AmigaGuide or Catalog files) are expected to be ISO-8859-1 encoded. Then again, `README.md` (and other files related to the open source release) are UTF-8 encoded. If you are in doubt, use plain ASCII.

## Contribution and Releases

The source code of this project can be found [at the official GitHub page](https://github.com/shred/identify).

If you found a bug or have a feature request, feel free to [open an issue](https://github.com/shred/identify/issues) or [send a pull request](https://github.com/shred/identify/pulls).

At the AmiNet, you will find [official binaries](http://aminet.net/package/util/libs/IdentifyUsr) and [development files](http://aminet.net/package/util/libs/IdentifyDev).

**Please keep the "IdentifyDev" and "IdentifyUsr" package names reserved for official releases.** If you want to release a fork, use a different package name. But please consider contributing to the reference repository instead. This is better than having an unknown number of different versions circulating around.

## Sync with your own Board Database?

If you're managing an own board database in your project, feel invited to sync it with [this database](src/identify/ID_Expansion.s). However, it would only be fair if you then also share the boards that are missing here. Please open an issue, send a merge request, or just get in contact with me. Thank you!

## What about Identify V37?

Identify V37 was released by Thore Böckelmann in 2003. This release added new boards and new features. He published it with good intentions, but unfortunately without my consent. I can only blame myself for that, because I haven't provided the infrastructure where a coordinated development was made possible. I hope that with this GitHub project, I can bring Identify back on track.

I have backported Thore's changes to the official repository. Thore also did a major version jump from V13 to V37, for no apparent reason. I will keep the new version numbering though.

For archiving purposes, you will find my last official Amiga built release V13.0, and Thore's V37.1, in the [GitHub releases](https://github.com/shred/identify/releases). Note that the code at the `v37.1` tag does not actually correspond to his V37.1 release, as he had used a completely different code base that was never published (to my knowledge).

## Licence

`Identify` is distributed under LGPLv3 ([Lesser Gnu Public Licence](http://www.gnu.org/licenses/lgpl.html)).
