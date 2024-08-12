# pdf2png

A small command line tool which renders pdf files into png files at various sizes,
with presets for rendering icons for iOS, MacOS and Android, and the ability to write
files directly into an xcassets package

<a id="support"></a>
## Support pdf2png!

Are you using pdf2png to build your apps? Would you like to help support the project and get a sponsor credit?

Visit our [Patreon Page](https://www.patreon.com/istumblerlabs) and patronize us in exchange for great rewards!

## sources

    gitlab: https://gitlab.com/alfwatt/pdf2png
    github: https://github.com/alfwatt/pdf2png

## usage

    usage: pdf2png -i <input.pdf> [-o <output-file-prefix>] [-s @,@2x,50,100x50,100@2x,400%]
        [-t ios|android-small|macos-small|android-large|ios-small|macos|ios-large|android|macos-large|retina]
        [-A Resources/Catalog.xcassets]

    -i — input file name, a PDF document
    -o — output file prefix, to which the size and .png will be appended
    -s — a comma seperated array of output sizes
    -t - a target group, which outputs a set of sizes suitable for icons

### Beta Options

These options are not well tested, YMMV

    -A - path to xcassets catalog to place the produced images into

### TODO Options

    -a YES|NO — include alpha channel, YES or NO
    -b 1|4|8|12 — bits per channel
    -c GRAY|INDEX|RGB|LAB|CMYK — color model
    -C x,y,w,h — crop to rectange 
    -v - version info
    -V - verbose
    -z — crush, generate the smallest PNG possible

## sizes

Output sizes can be expressed in a number of formats:

    @       - Original Size
    @2x     - Retina Sizes
    50      - Square Sizes (50x50)
    100x50  - Rectangular Sizes
    100@2x  - Square Retina Sizes (200,200)
    400%   - Percentage Sizes
    200w   - Fixed width, proportinate height
    200h   - Fixed height, proportinate width

## example

You have a logo for an application which is square, with large and small variants, that you want to render for both iOS and Android:

    $ pdf2png -i app-logo-small.pdf -o app-logo -t ios-small

Is equivalent to:

    $ pdf2png -i app-logo-small.pdf -o app-logo -s 29,29@2x,29@3x,40,40@2x,40@3x
    pdf2png wrote [29 x 29] pixels to app-logo_29x29.png
    pdf2png wrote [58 x 58] pixels to app-logo_29x29@2x.png
    pdf2png wrote [87 x 87] pixels to app-logo_29x29@3x.png
    pdf2png wrote [40 x 40] pixels to app-logo_40x40.png
    pdf2png wrote [80 x 80] pixels to app-logo_40x40@2x.png
    pdf2png wrote [120 x 120] pixels to app-logo_40x40@3x.png

To complete the set you can run:

    $ pdf2png -i app-logo-small.pdf -o app-logo -t android-small
    pdf2png wrote...
    
    $ pdf2png -i app-logo-large.pdf -o app-logo -t ios-large
    pdf2png wrote...
    
    $ pdf2png -i app-logo-large.pdf -o app-logo -t android-large
    pdf2png wrote...

## installing

Use the Makefile to install in /usr/local/bin

    make build
    sudo make install

## versions

- `1.0` — April 2016-ish

## license

    The MIT License (MIT)

    Copyright (c) 2015-2024 Alf Watt

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

