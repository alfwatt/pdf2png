# pdf2png

A small command line tool which renders pdf files into png files at various sizes,
with presets for rendering icons for iOS, MacOS and Android

## usage

    pdf2png -i <input.pdf> -o <output-file-prefix> -s 10,20x40,40x20 -R 1 -t <target>
        -i - input file name, a PDF
        -o - output file prefix, to which the size and .png will be appended
        -s - a comma seperated array of output sizes
        -R - generate retina versions of the image @2x
        -t - a target platform: macos, ios or android
           - macos:         -s 16,32,128,256,512 -R 1
           - macos-small:   -s 16,32 -R 1
           - macos-large:   -s 128,256,512 -R 1
           - ios:           -s 29,40,50,57,72,76,120 -R 1
           - ios-small:     -s 29,40,50,57 -R 1
           - ios-large:     -s 72,76,120 -R 1
           - android:       -s 36.48,72,96,144,192
           - android-small: -s 36.48,72
           - android-large: -s 96,144,192

## example

You have a logo for an application app-logo.pdf which you need to render for iOS and Android:

    pdf2png -i app-logo-small.pdf -t ios-small

Will genrate the following files:

    app-logo-29x29.png
    app-logo-29x29@2X.png
    app-logo-40x40.png
    app-logo-40x40@2X.png
    app-logo-50x50.png
    app-logo-50x50@2X.png
    app-logo-57x57.png
    app-logo-57x57@2X.png

--

The MIT License (MIT)

Copyright (c) 2015 Alf Watt

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

