# pdf2png

A small command line tool which renders pdf files into png files at various sizes, with presets for rendering logos for iOS and MacOS

## usage

    pdf2png -i <input.pdf> -o <output-file-prefix> -s 10,20,30,40 -R 1 -t macos|ios|android
        -i - input file name, a PDF
        -o - output file prefix, to which the size and .png will be appended
        -s - a comma seperated array of output sizes
        -R - generate retina versions of the image @2x
        -t - a target platform: macos, ios or android
           - macos is equivalent to: -s 16,32,128,256 -R 1
           - ios is equivalant to -s 29,40,50,57,72,76,120 -R 1
           - android is equilvalent to: -s 36.48,72,96,144,192

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

