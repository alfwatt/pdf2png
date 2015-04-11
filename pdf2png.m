#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

#pragma mark -

@interface NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error;

@end

#pragma mark -

@implementation NSImage (SSWPNGAdditions)

- (BOOL)writePNGToURL:(NSURL*)URL outputSizeInPixels:(NSSize)outputSizePx error:(NSError*__autoreleasing*)error
{
    BOOL result = YES;
    NSImage* scalingImage = [NSImage imageWithSize:[self size] flipped:[self isFlipped] drawingHandler:^BOOL(NSRect dstRect) {
        [self drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:dstRect operation:NSCompositeSourceOver fraction:1.0];
        return YES;
    }];
    NSRect proposedRect = NSMakeRect(0.0, 0.0, outputSizePx.width, outputSizePx.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef cgContext = CGBitmapContextCreate(NULL, proposedRect.size.width, proposedRect.size.height, 8, 4*proposedRect.size.width, colorSpace, kCGImageAlphaPremultipliedLast);
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
        NSString* retina = [args objectForKey:@"R"];
        NSArray* outputSizes = [[args objectForKey:@"s"] componentsSeparatedByString:@","];
        NSArray* targetSizes = nil;
        
        // ios or android target sizes

        if( [target isEqualToString:@"macos"])
        {
            retina = @"YES";
            targetSizes = @[@"512",
                            @"256",
                            @"128",
                            @"32",      // small
                            @"16"];     // small
        }
        else if( [target isEqualToString:@"ios"])
        {
            retina = @"YES";
            targetSizes = @[@"512",     // iTunes store @2X
                            @"120",     // iPhone iOS 7
                            @"76",      // iPad iOS 7
                            @"72",      // iPad iOS 6
                            @"57",      // iPhone iOS 6
                            @"50",      // Spotlight small
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
            NSLog(@"usage: pdf2png -i <input.pdf> -o <output-file-prefix> -s 10,20,30,40 -t macos|ios|android -R 1");
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
            // TODO check for 123x123 or 123% and scale appropriatlyz
            CGFloat size = [sizeString doubleValue];
            
            if( size > 10000) // proposed image is very very large, bigger than any current display
            {
                NSLog(@"ERROR: I'm sorry, Dave, I'm afraid I can't do that.");
                goto exit;
            }
            
            NSSize iconSize = NSMakeSize(size,size);
            
            NSError* error = nil;
            NSURL* outputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%.0fx%.0f.png",outputFilePrefix,size,size]];
            [icon writePNGToURL:outputFileURL outputSizeInPixels:iconSize error:&error];
            
            if( error) NSLog(@"ERROR: %@ writing: %@", error, outputFileURL);
            else NSLog(@"wrote: %@", outputFileURL);

            // now write the retina images if requested
            
            if( retina)
            {
                NSSize retinaSize = NSMakeSize(size*2,size*2);
                NSURL* retinaFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%.0fx%.0f@2x.png",outputFilePrefix,size,size]];
                [icon writePNGToURL:retinaFileURL outputSizeInPixels:retinaSize error:&error];
                
                if( error) NSLog(@"ERROR: %@ writing: %@", error, retinaFileURL);
                else NSLog(@"wrote: %@", retinaFileURL);
            }
            
        }
    }

exit:
    
    return status;
}

