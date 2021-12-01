# Frequently Asked Questions

## Expansions

**My board is not found, or not described correctly.**

Please open an issue, or get in contact with me. I will add your board to the internal Expansion database, so it will be decoded properly in the next release.

## System Analyzer

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