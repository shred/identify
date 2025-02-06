# Submitting Pull Requests

Identify is open source, which also means that it is open for your contributions.

To make contributing as easy and enjoyable for you as for me, there are a few rules that I kindly ask you to follow.

## How to Contribute

1. Create a fork of this project.
1. Modify your fork.
1. If you are done, make sure all technical requirements below are fulfilled.
1. Create a Merge Request, and wait for review or merge.

If you want to change different aspects (e.g. fix a bug and also provide a new board to the expansion database), please post separate Merge Requests for each topic. This way, a pending discussion for one change won't block the other from being merged.

Also please make sure to make nice git commits with speaking comments (this is, not just a single commit commented with "Changes").

## Requirements

For a successful Merge Request, make sure that these preconditions are met:

- [ ] You own the copyright of your contribution, and you agree that your work is distributed under [LGPLv3](LICENSE.txt) license.
- [ ] You keep the formatting, and use the correct character sets.
- [ ] You tested your changes.
- [ ] You keep the Assembler, C and Pascal include files in sync if you made changes to any files in the `reference` directory.
- [ ] You document your changes (if applicable).

## Translations

Translations of the locale files are very welcome as contribution. These preconditions need to be met for translations:

- [ ] Your translation **must** base on either the English or German locale files. I want to avoid translation chains, as they slow down the translation process, and might give inferior results because of translation errors adding up.
- [ ] Please state in your Merge Request if you will be available for translating upcoming new strings. It's okay if you only want to contribute once, but then I would have to resort to machine translation for new strings, or even remove your translation again some day when it becomes too outdated.

## Not Acceptable

There are a few changes that I am not going to accept.

- The target platform for Identify is the classic AmigaOS line that is based on the 68000 architecture. I won't accept changes related to AmigaOS 4, MorphOS, and other AmigaOS derivates. There are number of reasons for that, but mainly it's because I won't be able to test or maintain those changes.

- I won't accept major changes to the project, unless I am confident that I am able to keep them maintained by myself. I want to avoid a project stalemate because you might lose interest in your contribution some day, and I am unable to keep it updated.

- I won't accept changes to the expansion database if I have strong doubts that the changes are correct.

In general, I want to be benevolent and try to merge all of your changes. However, please respect that I want to keep a "final say", so I reserve the right to reject your merge requests without giving you reasons for that.

If you are not sure if I would accept your change, you can open a [new issue](https://codeberg.org/shred/identify/issues) and discuss it first.
