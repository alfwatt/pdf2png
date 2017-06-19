#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#pragma mark -

/* http://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues */

@interface NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSize:(NSSize)outputSizePx alphaChannel:(BOOL)alpha error:(NSError*__autoreleasing*)error;

@end

#pragma mark -

@implementation NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSize:(NSSize)outputSizePx alphaChannel:(BOOL)alpha error:(NSError*__autoreleasing*)error
{
    BOOL result = YES;
    NSImage* scalingImage = [NSImage imageWithSize:self.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [self drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:dstRect operation:NSCompositeSourceOver fraction:1.0];
        return YES;
    }];
    NSRect proposedRect = NSMakeRect(0.0, 0.0, outputSizePx.width, outputSizePx.height);
    unsigned components = 4; // TODO -c
    unsigned bitsPerComponent = 8; // TODO -
    unsigned bytesPerRow = proposedRect.size.width * (components * (bitsPerComponent / BYTE_SIZE));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef cgContext = CGBitmapContextCreate(NULL,
        proposedRect.size.width, proposedRect.size.height,
        bitsPerComponent, bytesPerRow, colorSpace, (alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst));
    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];

    NSDictionary* hints = @{(id)kCGImagePropertyHasAlpha: @(alpha)};
    CGImageRef cgImage = [scalingImage CGImageForProposedRect:&proposedRect context:context hints:hints];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)(URL), kUTTypePNG, 1, NULL);
    CFDictionaryRef imageOptions = CFBridgingRetain(hints);
    CGImageDestinationAddImage(destination, cgImage, imageOptions);
    if(!CGImageDestinationFinalize(destination)) {
        NSDictionary* details = @{NSLocalizedDescriptionKey:@"Error writing PNG image"};
        [details setValue:@"ran out of money" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"SSWPNGAdditionsErrorDomain" code:10 userInfo:details];
        result = NO;
    }
exit:
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(cgContext);
    CFRelease(destination);
    CFRelease(imageOptions);
    return result;
}

@end

#pragma mark -

enum {
    StatusUnkonwn = -1,
    StatusSuccess = 0,
    StatusInvalidTargetName,
    StatusMissingArguments,
    StatusInputFileNotFound,
    StatusInputFileNotAnImage,
    StatusOutputSizeInvalid,
    StatusOutputWriteError
};

int main(int argc, const char * argv[])
{
    int status = StatusUnkonwn;
    @autoreleasepool
    {
        NSFileHandle* stdout = [NSFileHandle fileHandleWithStandardOutput];
        NSDictionary* args = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
//        NSLog(@"args: %@", args);
        
        NSString* inputFileName = [args objectForKey:@"i"];
        NSString* outputFilePrefix = [args objectForKey:@"o"];
        NSString* target = [args objectForKey:@"t"];
        NSArray* outputSizes = [[args objectForKey:@"s"] componentsSeparatedByString:@","];
        NSNumber* alphaArg = [args objectForKey:@"a"];

        BOOL alphaChannel = YES;
        if (alphaArg) {
            alphaChannel = [alphaArg boolValue];
        }

        /*
        NSNumber* bitsArg = [args objectForKey:@"b"];
        unsigned bitsPerChannel = 8;
        if (bitsArg) {
            bitsPerChannel = [bitsArg unsignedIntValue];
            // TODO check for valid number of bits per channel
        }
        */


        NSDictionary* const targets = @{
            @"android": @[
                @"512",     // Google Play
                @"192",     // xxxhdpi
                @"144",     // xxhdpi
                @"96",      // xhdpi
                @"72",      // hdpi
                @"48",      // mdpi small
                @"36"       // ldpi small
            ],
            @"android-small": @[
                @"72",      // hdpi
                @"48",      // mdpi small
                @"36"       // ldpi small
            ],
            @"android-large": @[
                @"512",     // Google Play
                @"192",     // xxxhdpi
                @"144",     // xxhdpi
                @"96"       // xhdpi
            ],

            @"ios": @[
                @"29", @"29@2x",            // iPad Settings
                @"40", @"40@2x",            // iPad Spotlight
                @"76", @"76@2x",            // iPad App
                @"83.5@2x",                 // iPad Pro
                @"60@2x", @"60@3x",         // iPhone App
                @"29@3x",                   // iPhone Settings
                @"40@3x",                   // iPhone Spotlight
                @"512"                      // iTunes Store
            ],
            @"ios-small": @[
                @"29", @"29@2x", @"29@3x",  // Settings
                @"40", @"40@2x", @"40@3x"   // Spotlight
            ],
            @"ios-large": @[
                @"76", @"76@2x",            // iPad App
                @"83.5@2x",                 // iPad Pro
                @"60@2x", @"60@3x",         // iPhone App
                @"512"                      // iTunes Store
            ],

            @"macos": @[
                @"16", @"16@2x",
                @"32", @"32@2x",
                @"128", @"128@2x",
                @"256", @"256@2x",
                @"512", @"512@2x"
            ],
            @"macos-small": @[
                @"16", @"16@2x",
                @"32", @"32@2x"
            ],
            @"macos-large": @[
                @"128", @"128@2x",
                @"256", @"256@2x",
                @"512", @"512@2x"
            ],

            @"retina": @[
                @"@", @"@2x", @"@3x"
            ]
        };

        NSArray* targetSizes = nil;
        if (target && ((targetSizes = [targets objectForKey:target]) == nil)) {
            status = StatusInvalidTargetName;
            NSLog(@"Error %i: invalid target name: %@", status, target);
            goto exit;
        }

        if (outputSizes && targetSizes) { // combine the output and target sizes
            outputSizes = [outputSizes arrayByAddingObjectsFromArray:targetSizes];
        }
        else if (targetSizes && !outputSizes) {
            outputSizes = targetSizes;
        }

        if (!outputSizes) { // assume a single 100% size
            outputSizes = @[@"@"];
        }

        if (!outputFilePrefix) { // infer it from the inputFileName
            outputFilePrefix = [[inputFileName lastPathComponent] stringByDeletingPathExtension];
        }
        
        if (!inputFileName || !outputSizes) {
            NSString* usage = [NSString stringWithFormat:
                @"usage: pdf2png -i <input.pdf> [-o <output-file-prefix>] [-s @,@2x,50,100x100,100@2x,400%%] [-a YES|NO] \n\t[-t %@]\n",
                [[targets.allKeys sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"|"]];
            [stdout writeData:[usage dataUsingEncoding:NSUTF8StringEncoding]];
            status = StatusMissingArguments;
            goto exit;
        }
                
        if (![[NSFileManager defaultManager] fileExistsAtPath:inputFileName isDirectory:nil]) {
            status = StatusInputFileNotFound;
            NSLog(@"Error %i: input file not found: %@", status, inputFileName);
            goto exit;
        }
        
        // create a target NSImage at each of the specified sizes
        NSImage* icon = [[NSImage alloc] initByReferencingFile:inputFileName];
        if (!icon) {
            status = StatusInputFileNotAnImage;
            NSLog(@"Error %i: image did not load from: %@", status, inputFileName);
            goto exit;
        }
        
        // write the target NSImage to the output-file-prefix specified
        for (NSString* sizeString in outputSizes) {
            BOOL isRetina = NO;
            NSSize pointSize = icon.size;
            NSSize outputSize = icon.size;
            NSString* retinaSize = nil;

            // check for size formats: @ @2x 123@2x 123x123 123% 123w 123h 123 and scale appropriately
            if ([sizeString isEqualToString:@"@"]) { // 100%
                // sizes are set above, just keep going
                isRetina = YES;
            }
            else if ([sizeString rangeOfString:@"@"].location == 0) { // multiply the existing size
                isRetina = YES;
                retinaSize = [sizeString substringFromIndex:1];
                CGFloat retina = [[retinaSize substringToIndex:(retinaSize.length - 1)] doubleValue];
                outputSize = NSMakeSize(pointSize.width * retina, pointSize.height * retina);
            }
            else if ([sizeString rangeOfString:@"@"].location != NSNotFound) {
                NSArray* sizeComponents = [sizeString componentsSeparatedByString:@"@"];
                retinaSize = sizeComponents[1]; // "2x" for the file name
                CGFloat pixels = [sizeComponents[0] doubleValue];
                CGFloat retina = [[retinaSize substringToIndex:(retinaSize.length - 1)] doubleValue];
                CGFloat retinaPixels = pixels * retina;
                pointSize = NSMakeSize( pixels, pixels);
                outputSize = NSMakeSize( retinaPixels, retinaPixels);
            }
            else if ([sizeString rangeOfString:@"x"].location < sizeString.length) { // anywhere but at the end of the string
                NSArray* sizeArray = [sizeString componentsSeparatedByString:@"x"];
                if (sizeArray.count == 2 ) { // widthxheight
                    CGFloat width = [sizeArray[0] doubleValue];
                    CGFloat height = [sizeArray[1] doubleValue];
                    pointSize = NSMakeSize( width, height);
                    outputSize = NSMakeSize( width, height);
                }
            }
            else if ([sizeString rangeOfString:@"%"].location == (sizeString.length - 1)) { // only at the end of the string
                NSString* percentString = [sizeString substringToIndex:(sizeString.length - 2)];
                CGFloat percentSize = ([percentString doubleValue] / 10);
                outputSize = NSMakeSize((icon.size.width * percentSize), (icon.size.height * percentSize));
                pointSize = outputSize;
            }
            else if ([sizeString rangeOfString:@"h"].location == (sizeString.length - 1)) { // fixed height
                NSString* widthString = [sizeString substringToIndex:(sizeString.length - 2)];
                CGFloat fixedWidth = [widthString doubleValue];
                CGFloat scaleFactor = (icon.size.width / fixedWidth);
                outputSize = NSMakeSize(fixedWidth, (icon.size.height * scaleFactor));
                pointSize = outputSize;
            }
            else if ([sizeString rangeOfString:@"w"].location == (sizeString.length - 1)) { // fixed width
                NSString* heightString = [sizeString substringToIndex:(sizeString.length - 2)];
                CGFloat fixedHeight = [heightString doubleValue];
                CGFloat scaleFactor = (icon.size.height / fixedHeight);
                outputSize = NSMakeSize((icon.size.width * scaleFactor), fixedHeight);
                pointSize = outputSize;
            }
            else { // it's a simple square size
                CGFloat size = [sizeString doubleValue];
                pointSize = NSMakeSize(size, size);
                outputSize = NSMakeSize(size, size);
            }
            
            if (outputSize.width < 1 || outputSize.height < 1 // proposed image is less than 1x1
             || outputSize.width > 10000 || outputSize.height > 10000) { // proposed image is larger than any current display
                status = StatusOutputSizeInvalid;
                NSLog(@"Error %i: Invalid output size: %@ -> %@", status, sizeString, NSStringFromSize(outputSize));
                goto exit;
            }

            NSError* error = nil;
            NSString* outputFileName = nil;
            if (isRetina) {
                outputFileName = outputFilePrefix;
            }
            else {
                outputFileName = [NSString stringWithFormat:@"%@_%.0fx%.0f", outputFilePrefix, pointSize.width, pointSize.height];
            }

            if (retinaSize) { // append the retina tag
                outputFileName = [outputFileName stringByAppendingString:@"@"];
                outputFileName = [outputFileName stringByAppendingString:retinaSize];
            }
            outputFileName = [outputFileName stringByAppendingPathExtension:@"png"];
            [icon writePNGToURL:[NSURL fileURLWithPath:outputFileName] outputSize:outputSize alphaChannel:alphaChannel error:&error];
            
            if (error) {
                status = StatusOutputWriteError;
                NSLog(@"Error %i: %@ writing: %@", status, error, outputFileName);
                goto exit;
            }

            [stdout writeData:[[NSString stringWithFormat:@"pdf2png wrote [%.0f x %.0f] pixels to %@\n",
                outputSize.width, outputSize.height, outputFileName] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    status = StatusSuccess;
exit:
    
    return status;
}

