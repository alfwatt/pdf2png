#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

#pragma mark -

/* http://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues */

@interface NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error;

@end

#pragma mark -

@implementation NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error
{
    BOOL result = YES;
    NSImage* scalingImage = [NSImage imageWithSize:self.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [self drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:dstRect operation:NSCompositeSourceOver fraction:1.0];
        return YES;
    }];
    NSRect proposedRect = NSMakeRect(0.0, 0.0, outputSizePx.width, outputSizePx.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef cgContext = CGBitmapContextCreate(NULL, proposedRect.size.width, proposedRect.size.height, 8, 4*proposedRect.size.width, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    CGContextRelease(cgContext);
    CGImageRef cgImage = [scalingImage CGImageForProposedRect:&proposedRect context:context hints:nil];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)(URL), kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, cgImage, nil);
    if(!CGImageDestinationFinalize(destination))
    {
        NSDictionary* details = @{NSLocalizedDescriptionKey:@"Error writing PNG image"};
        [details setValue:@"ran out of money" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"SSWPNGAdditionsErrorDomain" code:10 userInfo:details];
        result = NO;
    }
    CFRelease(destination);
    return result;
}

@end

#pragma mark -

int main(int argc, const char * argv[])
{
    int status = 0;
    @autoreleasepool
    {
        NSDictionary* args = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
//        NSLog(@"args: %@", args);
        
        // load the pdf into an NSImage
        NSString* inputFileName = [args objectForKey:@"i"];
        NSString* outputFilePrefix = [args objectForKey:@"o"];
        NSString* target = [args objectForKey:@"t"];
        NSArray* outputSizes = [[args objectForKey:@"s"] componentsSeparatedByString:@","];
        NSArray* retinaSizes = [[args objectForKey:@"R"] componentsSeparatedByString:@","];
        NSArray* targetSizes = nil;
        
        // ios or android target sizes

        if( [target isEqualToString:@"macos"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"512",
                            @"256",
                            @"128",
                            @"32",      // small
                            @"16"];     // small
        }
        if( [target isEqualToString:@"macos-small"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"32",      // small
                            @"16"];     // small
        }
        if( [target isEqualToString:@"macos-large"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"512",
                            @"256",
                            @"128"];
        }
        else if( [target isEqualToString:@"ios"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"512",     // iTunes store @2X
                            @"120",     // iPhone iOS 7
                            @"76",      // iPad iOS 7
                            @"72",      // iPad iOS 6
                            @"57",      // iPhone iOS 6
                            @"50",      // Spotlight small
                            @"40",      // Spotlight small
                            @"29"];     // Settings small
        }
        else if( [target isEqualToString:@"ios-small"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"50",      // Spotlight small
                            @"40",      // Spotlight small
                            @"29",      // Settings small
                            @"72"];     // iPad iOS 6

        }
        else if( [target isEqualToString:@"ios-large"])
        {
            retinaSizes = @[@"2"];
            targetSizes = @[@"512",     // iTunes store @2X
                            @"120",     // iPhone iOS 7
                            @"76"];     // iPad iOS 7

        }
        else if( [target isEqualToString:@"ios8"])
        {
            retinaSizes = @[@"2",@"3"];
            targetSizes = @[@"76",      // iPad App
                            @"60",      // iPhone App
                            @"40",      // Spotlight small
                            @"29"];     // Settings small
        }
        else if( [target isEqualToString:@"android"])
        {
            targetSizes = @[@"512",     // Google Play
                            @"192",     // xxxhdpi
                            @"144",     // xxhdpi
                            @"96",      // xhdpi
                            @"72",      // hdpi
                            @"48",      // mdpi small
                            @"36"];     // ldpi small
        }
        else if( [target isEqualToString:@"android-small"])
        {
            targetSizes = @[@"72",      // hdpi
                            @"48",      // mdpi small
                            @"36"];     // ldpi small
        }
        else if( [target isEqualToString:@"android-large"])
        {
            targetSizes = @[@"512",     // Google Play
                            @"192",     // xxxhdpi
                            @"144",     // xxhdpi
                            @"96"];     // xhdpi
        }

        // combine the output and target sizes
        if( outputSizes && targetSizes)
        {
            outputSizes = [outputSizes arrayByAddingObjectsFromArray:targetSizes];
        }
        else if ( targetSizes && !outputSizes)
        {
            outputSizes = targetSizes;
        }
        
        if( !inputFileName || !outputFilePrefix || !outputSizes)
        {
            NSFileHandle* stdout = [NSFileHandle fileHandleWithStandardOutput];
            [stdout writeData:[@"usage: pdf2png -i <input.pdf> -o <output-file-prefix> -s 10,20,30,40 -t macos|ios|android -R 1\n" dataUsingEncoding:NSUTF8StringEncoding]];
            goto exit;
        }
                
        if( ![[NSFileManager defaultManager] fileExistsAtPath:inputFileName isDirectory:nil] )
        {
            NSLog(@"ERROR input file not found: %@", inputFileName);
            goto exit;
        }
        
        // create a target NSImage at each of the specified sizes
        NSImage* icon = [[NSImage alloc] initByReferencingFile:inputFileName];
        if( !icon)
        {
            NSLog(@"ERROR image did not load from: %@", inputFileName);
            goto exit;
        }
        
//      NSRect sourceRect = NSMakeRect(0,0,icon.size.width,icon.size.height);

        // write the target NSImage to the output-file-prefix specified
        for( NSString* sizeString in outputSizes)
        {
            NSSize iconSize;

            // TODO check for 123x123 or 123% and scale appropriatlyz
            NSArray* sizeArray = [sizeString componentsSeparatedByString:@"x"];
            if( sizeArray.count == 2 )// widthxheight
            {
                CGFloat width = [sizeArray[0] doubleValue];
                CGFloat height = [sizeArray[1] doubleValue];
                iconSize = NSMakeSize( width, height);
            }
            else // it's square
            {
                CGFloat size = [sizeString doubleValue];
                iconSize = NSMakeSize(size, size);
            }
            
            if( iconSize.width < 1 || iconSize.height < 1 // proposed image is less than one pixel in either dimension
             || iconSize.width > 10000 || iconSize.height > 10000) // proposed image is very very large, bigger than any current display
            {
                NSLog(@"ERROR: Invalid image size: %@ -> %@", sizeString, NSStringFromSize(iconSize));
                goto exit;
            }

            NSError* error = nil;
            NSURL* outputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%.0fx%.0f.png",outputFilePrefix,iconSize.width,iconSize.height]];
            [icon writePNGToURL:outputFileURL outputSizeInPixels:iconSize error:&error];
            
            if( error) NSLog(@"ERROR: %@ writing: %@", error, outputFileURL);
            else NSLog(@"wrote: %@", outputFileURL);

            // now write the retina images if requested
            
            if( retinaSizes)
            {
                for( NSString* multiple in retinaSizes)
                {
                    CGFloat scale = [multiple doubleValue];
                    NSSize retinaSize = NSMakeSize(iconSize.width*scale,iconSize.height*scale);
                    NSURL* retinaFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%.0fx%.0f@%.0fx.png",outputFilePrefix,iconSize.width,iconSize.height,scale]];
                    [icon writePNGToURL:retinaFileURL outputSizeInPixels:retinaSize error:&error];
                    
                    if( error) NSLog(@"ERROR: %@ writing: %@", error, retinaFileURL);
                    else NSLog(@"wrote: %@", retinaFileURL);
                }
            }
            
        }
    }

exit:
    
    return status;
}

