#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#define PDF2PNG_VERSION "1.1.1"
#define PDF2PNG_BUILD   "101010.0"

/*
    http://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues
*/
@interface NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSize:(NSSize)outputSizePx alphaChannel:(BOOL)alpha error:(NSError*__autoreleasing*)error;

@end

// mark: -

@implementation NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSize:(NSSize)outputSizePx alphaChannel:(BOOL)alpha error:(NSError*__autoreleasing*)error {
    BOOL result = YES;
    NSImage* sourceImage = [NSImage imageWithSize:self.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [self drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:dstRect operation:NSCompositingOperationSourceOver fraction:1.0];
        return YES;
    }];
    NSRect proposedRect = NSMakeRect(0.0, 0.0, outputSizePx.width, outputSizePx.height);
    unsigned bitsPerComponent = 8;
    unsigned components = (alpha ? 4 : 3);
    unsigned bytesPerRow = proposedRect.size.width * (components * (bitsPerComponent / BYTE_SIZE));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    CGContextRef cgContext = CGBitmapContextCreate(
        NULL, proposedRect.size.width, proposedRect.size.height,
        bitsPerComponent, bytesPerRow, colorSpace,
        (alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone));
    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithCGContext:cgContext flipped:NO];

    if (proposedRect.size.width != outputSizePx.width) {
        NSLog(@"WARNING proposedRect.size: %@ != outputSizePx %@", NSStringFromSize(proposedRect.size), NSStringFromSize(outputSizePx));
    }

    // scale the image
    CGImageRef scaledImage = [sourceImage CGImageForProposedRect:&proposedRect context:context hints:@{
        NSImageHintCTM: NSAffineTransform.transform
    }];
    NSSize scaledSize = NSMakeSize(CGImageGetWidth(scaledImage), CGImageGetHeight(scaledImage));

    if (scaledSize.width != outputSizePx.width) {
        NSLog(@"WARNING scaledSize: %@ != outputSizePx %@", NSStringFromSize(scaledSize), NSStringFromSize(outputSizePx));
    }
    
    // setup the destination
    NSDictionary* options = @{
        (id)kCGImagePropertyHasAlpha: @(alpha)
    };

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)(URL), kUTTypePNG, 1, NULL);
    CFDictionaryRef destinationOptions = CFBridgingRetain(options);
    CGImageDestinationSetProperties(destination, destinationOptions);
    CGImageDestinationAddImage(destination, scaledImage, destinationOptions);

    // write the image
    // NSLog(@"scaled alphaInfo: %u %u %@", alpha, CGImageGetAlphaInfo(scaledImage), destinationOptions);
    if(!CGImageDestinationFinalize(destination)) {
        NSDictionary* details = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Error writing PNG to: %@", URL] };
        *error = [NSError errorWithDomain:@"SSWPNGAdditionsErrorDomain" code:10 userInfo:details];
        result = NO;
    }

exit:
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(cgContext);
    CFRelease(destination);
    CFRelease(destinationOptions);
    return result;
}

@end

// MARK: - main

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

int main(int argc, const char * argv[]) {
    int status = StatusUnkonwn;
    @autoreleasepool {
        NSDictionary* args = [NSUserDefaults.standardUserDefaults volatileDomainForName:NSArgumentDomain];
//        NSLog(@"args: %@", args);
        
        NSString* inputFileName = [args objectForKey:@"i"];
        NSString* outputFilePrefix = [args objectForKey:@"o"];
        NSString* target = [args objectForKey:@"t"];
        NSArray* outputSizes = [[args objectForKey:@"s"] componentsSeparatedByString:@","];
        NSNumber* alphaArg = [args objectForKey:@"a"];
        NSString* assetCatalog = [args objectForKey:@"A"];

        BOOL alphaChannel = YES;
        if (alphaArg) {
            alphaChannel = alphaArg.boolValue;
        }
        else if (target && [target rangeOfString:@"ios" options:NSAnchoredSearch].location != NSNotFound) { // iOS icons can't have an alpha channel
            alphaChannel = NO;
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
            // Android
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
            // iOS
            @"ios": @[
                @"20", @"20@2x", @"20@3x",  // Notificaiton
                @"29", @"29@2x", @"29@3x",  // Settings
                @"40", @"40@2x",            // iPad Spotlight
                @"76", @"76@2x",            // iPad App
                @"83.5@2x",                 // iPad Pro
                @"60@2x", @"60@3x",         // iPhone App
                @"40@3x",                   // iPhone Spotlight
                @"1024"                     // iTunes Store
            ],
            @"ios-small": @[
                @"20", @"20@2x", @"20@3x",  // Notificaitons
                @"29", @"29@2x", @"29@3x",  // Settings
                @"40", @"40@2x", @"40@3x"   // Spotlight
            ],
            @"ios-large": @[
                @"76", @"76@2x",            // iPad App
                @"83.5@2x",                 // iPad Pro
                @"60@2x", @"60@3x",         // iPhone App
                @"1024"                     // iTunes Store
            ],
            // macOS
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
            // Messages
            @"messages-icon": @[ // iMessages App Icon
                @"1024"
            ],
            
            @"messages-settings": @[ // iMessages App Settings Icon
                @"29@2x", @"29@3x"
            ],

            @"messages": @[
                @"1024x768@2x", @"1024x768@3x", // App Store - 1.3~
                @"32x24@2x", @"32x24@3x", // Messages - 1.3~
                @"27x20@2x", @"27x20@3x", // Messages - 1.35
                @"67x50@2x", // Messages iPad - 1.34
                @"74x55@2x", // Messages iPad Pro - 1.3454545455
            ],
            // Retina sizes
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

        if (!inputFileName || !outputSizes) {
            NSString* usage = [NSString stringWithFormat:
                @"usage: pdf2png -i <input.pdf> [-o <output-file-prefix>] [-s @,@2x,50,100x100,100@2x,400%%] [-a YES|NO] \n\t[-t %@]\nVersion %@ - %@\n",
                [[targets.allKeys sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"|"], @PDF2PNG_VERSION, @PDF2PNG_BUILD];
            [NSFileHandle.fileHandleWithStandardOutput writeData:[usage dataUsingEncoding:NSUTF8StringEncoding]];
            status = StatusMissingArguments;
            goto exit;
        }
                
        if (![NSFileManager.defaultManager fileExistsAtPath:inputFileName isDirectory:nil]) {
            status = StatusInputFileNotFound;
            NSLog(@"Error %i: input file not found: %@", status, inputFileName);
            goto exit;
        }
        
        // create a target NSImage at each of the specified sizes
        NSImage* icon = [NSImage.alloc initByReferencingFile:inputFileName];
        if (!icon) {
            status = StatusInputFileNotAnImage;
            NSLog(@"Error %i: image did not load from: %@", status, inputFileName);
            goto exit;
        }
        
        // now that we know we can read the check to see if we're writing into an asset catalog
        if (assetCatalog) {
            outputFilePrefix = [[assetCatalog stringByAppendingPathComponent:outputFilePrefix] stringByAppendingPathExtension:@"imageset"];
            NSURL* iamgesetURL = [NSURL fileURLWithPath:outputFilePrefix]; // resolved relative to working directory
            BOOL isDirectory = NO;
            NSError* createError = nil;
            
            if ([NSFileManager.defaultManager fileExistsAtPath:iamgesetURL.path isDirectory:&isDirectory]) {
                if (!isDirectory) { // strange condtion, exit
                    status = -420;
                    NSLog(@"ERROR %i: iamgeset exists but is not a directory: %@", status, outputFilePrefix);
                    goto exit;
                }
            }
            else { // need to create the imageset
                if (![NSFileManager.defaultManager createDirectoryAtPath:iamgesetURL.path withIntermediateDirectories:YES attributes:nil error:&createError]) {
                    status = -421;
                    NSLog(@"Error %i: cannot create imageset: %@", status, iamgesetURL.path);
                    goto exit;
                }
            }
        }
        
        if (!outputFilePrefix) { // infer it from the inputFileName if neither -o or -A were specified
            outputFilePrefix = inputFileName.lastPathComponent.stringByDeletingPathExtension;
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
                CGFloat retina = [retinaSize substringToIndex:(retinaSize.length - 1)].doubleValue;
                outputSize = NSMakeSize(pointSize.width * retina, pointSize.height * retina);
            }
            else if ([sizeString rangeOfString:@"@"].location != NSNotFound) {
                NSArray* sizeComponents = [sizeString componentsSeparatedByString:@"@"];
                retinaSize = sizeComponents[1]; // "2x" for the file name
                CGFloat pixels = [sizeComponents[0] doubleValue];
                CGFloat retina = [retinaSize substringToIndex:(retinaSize.length - 1)].doubleValue;
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
                CGFloat percentSize = (percentString.doubleValue / 10);
                outputSize = NSMakeSize((icon.size.width * percentSize), (icon.size.height * percentSize));
                pointSize = outputSize;
            }
            else if ([sizeString rangeOfString:@"h"].location == (sizeString.length - 1)) { // fixed height
                NSString* heightString = [sizeString substringToIndex:(sizeString.length - 2)];
                CGFloat fixedHeight = heightString.doubleValue;
                CGFloat scaleFactor = (icon.size.height / fixedHeight);
                outputSize = NSMakeSize((icon.size.width * scaleFactor), fixedHeight);
                pointSize = outputSize;
            }
            else if ([sizeString rangeOfString:@"w"].location == (sizeString.length - 1)) { // fixed width
                NSString* widthString = [sizeString substringToIndex:(sizeString.length - 2)];
                CGFloat fixedWidth = widthString.doubleValue;
                CGFloat scaleFactor = (icon.size.width / fixedWidth);
                outputSize = NSMakeSize(fixedWidth, (icon.size.height * scaleFactor));
                pointSize = outputSize;
            }
            else { // it's a simple square size
                CGFloat size = sizeString.doubleValue;
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

            [NSFileHandle.fileHandleWithStandardOutput writeData:[[NSString stringWithFormat:@"pdf2png wrote [%.0f x %.0f] pixels to %@\n",
                outputSize.width, outputSize.height, outputFileName] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        if (assetCatalog) { // we need to update the plist in the catalog
        }
    }

    status = StatusSuccess;
exit:
    
    return status;
}

