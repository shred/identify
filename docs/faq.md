# Frequently Asked Questions

## Expansions

**My board is not found, or not described correctly.**

[See here](https://identify.shredzone.org/missing) about how to report a missing or incorrect expansion.

**I have made a new Amiga expansion. Can I register a manufacturer/product ID with you?**

Unfortunately, no. The identify database isn't the official registry of manufacturer and product IDs, so I'm not permitted to assign new manufacturer IDs.

This is what you can do now:

* If your hardware project is **fully open source**, you can apply for a product ID at the [Amiga Open Hardware Repository](https://oahr.github.io/oahr/). As an additional benefit, your hardware will be added to the identify database automatically.
* If you are a **member of the a1k.org Amiga board**, you can [apply for a product ID there](https://www.a1k.org/forum/index.php?threads/40276/) (German page, English posts are accepted). Your hardware will automatically be added to the identify database as soon as it is added to the boards.library.
* If none of these options are acceptable for you, you can still [obtain your own Manufacturer ID](https://wiki.amigaos.net/wiki/Amiga_Hardware_Manufacturer_ID_Registry) at Hyperion Entertainment CVBA. Your new hardware won't be added to the identify database automatically, so please remember to [send a report](https://identify.shredzone.org/missing) once you have your manufacturer and product ID.

## System Analyzer

**AmigaOS 3.2.2.1 is not detected properly.**

AmigaOS 3.2.2.1 is reported as AmigaOS 3.2.2. This is because AmigaOS 3.2.2.1 is a hotfix version of AmigaOS 3.2.2 which only updates a very small number of system files, so it is even less of an update than a BoingBag. For this reason, I have decided not to support sub-sub-minor version numbers, and instead to keep the version number "AmigaOS 3.2.2".

If Hyperion releases more hotfixes like this in the future, I may reconsider this decision.

**Why is there no CPU/FPU clock shown?**

On emulated Amigas, and systems with an FPGA processor, Identify won't give a CPU or FPU clock. This is because these systems work very differently than traditional processors, so the clock measurement would give a useless random number that does not truely correspond to the computing power.

The intention of Identify is to show your true CPU clock. If you need a benchmark test, you can use tools like [SysInfo](https://aminet.net/package/util/moni/SysInfo), which give a more realistic result.

**The CPU/FPU clock isn't accurate.**

Measuring the clock requires real Fast RAM for best results. If there is only Chip RAM, the results may be wrong. This is a technical limitation that cannot be compensated easily.

**The PowerPC clock isn't accurate.**

This is a bug in the `ppc.library`.

**The PowerPC clock isn't available.**

This occurs on some processors when running WarpOS.

**The system crashes during system analyzation (e.g. ListExp).**

Make sure that you have _not_ installed the `ppc.library` unless you really have a PPC processor.

## Alert Decoder

**An enforcer hit occurs while fetching the last alert.**

On DraCo, an enforcer hit occurs while the last alert is fetched. This alert is harmless and technically required.

## Running on Emulators

**Why is there no CPU/FPU clock shown?**

This is because the result would be rather random than representative. See the same quesion above for a more detailed explanation.

**Emulation is detected properly, but I do not get information about the host system.**

Information about the host system is only provided by the AmigaXL emulator. UAE does not provide this kind of information.

## Open Source

**Where do I find the source code?**

It's at the official [GitHub repository](https://github.com/shred/identify) and LGPLv3 licensed. Your contribution is welcome!

**I'm missing a translation for my language.**

In the source repository and the IdentifyDev package, you will find all files that are required for a translation. If you have created a translation file, you can open a pull request, or send me a mail. I will gladly add this file to the official project.

**I'd like to do a fork.**

Well, you _can_ do that. But please consider to contribute to the official project instead, so we won't have too many different versions circulating around. If you want to publish your fork to the AmiNet, please _do not use_ the "IdentifyDev" and "IdentifyUsr" package names, as they are reserved for official releases! Use own package names instead.

**What about Identify V37?**

Identify V37 was released by Thore Böckelmann in 2003. This release added new boards and new features. He published it with good intentions, but unfortunately without my consent. I can only blame myself for that, because I hadn't provided the infrastructure where a coordinated development was made possible.

All changes of Thore's release have been backported to this official repository. For archiving purposes, you will find my last official Amiga built release V13.0, and Thore's V37.1, in the [GitHub releases](https://github.com/shred/identify/releases). Note that the code at the `v37.1` tag does not actually correspond to his V37.1 release, as he had used a completely different code base that was never published (to my knowledge).
