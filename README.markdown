# LTFS Console

LTFS Console is a Linux console application for formatting, reading, and writing to LTFS formatted LTO tape cartridges. It has been written in Bash and Dialog, and at the moment supports only direct attached single unit LTO-5 (or above) tape drives.

Some utility and helper methods have come from PrestoPrime project [https://github.com/prestoprime/LTFSArchiver](https://github.com/prestoprime/LTFSArchiver)

## Installation

Installation instructions to follow.... requires compiling the standalone LTFS drivers. An Ubuntu example will be given. Also requires mt-st: mt-based (Mount Tape) utility with support for Linux SCSI tape. `sudo apt-get install mt-st`.

## Environment

This application was developed on Ubuntu 12.04 LTS, an HP DL160 server with a P212 SAS controller, and an HP Ultrium 3000 LTO-5 tape drive (although it should work with any LTO tape drive on any Linux distribution).

## Features

More soon..

## License

GNU AFFERO GENERAL PUBLIC LICENSE