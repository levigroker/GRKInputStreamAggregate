//
//  GRKInputStreamAggregate.m
//
//  Modified from CBLMultiStreamWriter.m, created by Jens Alfke on 2/3/12.
//  Copyright (c) 2012-2013 Couchbase, Inc. All rights reserved.
//
//  Created by Levi Brown on December 31, 2015.
//  Copyright 2015-2016 Levi Brown
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "GRKInputStreamAggregate.h"

#if GRK_DEBUG
#define DLog(...) NSLog(@"%s (%d) %s \"%@\"", __FILE__, __LINE__, __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...) do { } while (0)
#endif


NSUInteger const kGRKInputStreamAggregateDefaultBufferSize = 32768;

@interface GRKInputStreamAggregate () <NSStreamDelegate>

@property (readwrite,strong) NSError *error;
@property (strong) NSMutableArray *inputs;
@property (strong) NSInputStream *currentInput;
@property (strong) NSOutputStream *output;
@property (strong) NSInputStream *input;
@property (assign) NSUInteger nextInputIndex;
@property (assign) uint8_t* buffer;
@property (assign) NSUInteger bufferSize;
@property (assign) NSUInteger bufferLength;
@property (readwrite,assign) SInt64 length;
@property (assign) SInt64 totalBytesWritten;

@end

@implementation GRKInputStreamAggregate

#pragma mark - Lifecycle

- (void)dealloc
{
    [self close];
    free(_buffer);
}

- (instancetype)initWithBufferSize:(NSUInteger)bufferSize
{
    self = [super init];
    if (self)
    {
        _inputs = [[NSMutableArray alloc] init];
        _bufferLength = 0;
        _bufferSize = bufferSize;
        _buffer = malloc(_bufferSize);
        if (!_buffer)
        {
            return nil;
        }
    }
    return self;
}

- (instancetype)init
{
    return [self initWithBufferSize:kGRKInputStreamAggregateDefaultBufferSize];
}

#pragma mark - Implementation

- (void)addInput:(id)input length:(UInt64)length
{
    [self.inputs addObject:input];
    if (self.length >= 0)
    {
        self.length += length;
    }
}

- (void)addStream:(NSInputStream *)stream length:(UInt64)length
{
    [self addInput:stream length:length];
}

- (void)addStream:(NSInputStream *)stream
{
    DLog(@"Adding stream of unknown length: %@", stream);
    [self.inputs addObject:stream];
    self.length = -1;  // length is now unknown
}

- (void)addData:(NSData *)data
{
    if (data.length > 0)
    {
        [self addInput:data length:data.length];
    }
}

- (void) addString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self addData:data];
}

- (BOOL)addFileURL:(NSURL *)url
{
    BOOL retVal = NO;
    
    NSNumber *fileSizeObj;
    if ([url getResourceValue:&fileSizeObj forKey:NSURLFileSizeKey error:nil])
    {
        [self addInput:url length:fileSizeObj.unsignedLongLongValue];
        retVal = YES;
    }
    
    return retVal;
}

- (BOOL)addFile:(NSString*)path
{
    return [self addFileURL:[NSURL fileURLWithPath:path]];
}


#pragma mark - OPENING:


- (BOOL)isOpen
{
    return self.output.delegate != nil;
}

- (void)opened
{
    self.error = nil;
    self.totalBytesWritten = 0;
    
    self.output.delegate = self;
    [self.output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output open];
}

- (NSInputStream *)openForInputStream
{
    if (self.input)
    {
        return self.input;
    }
    
    NSAssert(!self.output, @"Already open");
    CFReadStreamRef cfInput;
    CFWriteStreamRef cfOutput;
    CFStreamCreateBoundPair(NULL, &cfInput, &cfOutput, self.bufferSize);
    self.input = CFBridgingRelease(cfInput);
    self.output = CFBridgingRelease(cfOutput);
    DLog(@"Opened input=%p, output=%p", self.input, self.output);
    [self opened];
    return self.input;
}

- (void)openForOutputTo:(NSOutputStream *)output
{
    NSAssert(output, @"Must have non-nil output");
    NSAssert(!self.output, @"Already open");
    NSAssert(!self.input, @"Must have nil input");
    self.output = output;
    [self opened];
}

- (void)close
{
    DLog(@"Closed");
    [self.output close];
    self.output.delegate = nil;
    
    /*
     https://github.com/couchbase/couchbase-lite-ios/issues/424
     Workaround for a race condition in CFStream _CFStreamCopyRunLoopsAndModes. 
     This outputstream needs to be retained just a little longer.
     Source: https://github.com/AFNetworking/AFNetworking/issues/907
     */
    NSOutputStream *outputStream = self.output;
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        outputStream.delegate = nil;
    });
    
    self.output = nil;
    self.input = nil;
    
    self.bufferLength = 0;
    
    [self.currentInput close];
    self.currentInput = nil;
    self.nextInputIndex = 0;
}


#pragma mark - I/O:


- (NSInputStream *)streamForInput:(id)input
{
    NSInputStream *retVal = nil;
    
    if ([input isKindOfClass:[NSData class]])
    {
        retVal = [NSInputStream inputStreamWithData:input];
    }
    else if ([input isKindOfClass:[NSURL class]] && [input isFileURL])
    {
        retVal = [NSInputStream inputStreamWithFileAtPath:[input path]];
    }
    else if ([input isKindOfClass:NSInputStream.class])
    {
        retVal = input;
    }
    else
    {
        NSAssert(NO, @"Invalid input class %@ for CBLMultiStreamWriter", [input class]);
    }
    
    return retVal;
}

// Close the current input stream and open the next one, assigning it to self.currentInput.
- (BOOL)openNextInput
{
    BOOL retVal = NO;
    
    if (self.currentInput)
    {
        [self.currentInput close];
        self.currentInput = nil;
    }
    
    if (self.nextInputIndex < self.inputs.count)
    {
        self.currentInput = [self streamForInput:self.inputs[self.nextInputIndex]];
        ++self.nextInputIndex;
        [self.currentInput open];
        retVal = YES;
    }
    
    return retVal;
}

// Set my .error property from 'stream's error.
- (void)setErrorFrom:(NSStream *)stream
{
    NSError *error = stream.streamError;
    DLog(@"[WARN] Error on %@:%@", stream, error);
    if (error && !self.error)
    {
        self.error = error;
    }
}

// Read up to 'len' bytes from the aggregated input streams to 'buffer'.
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    NSInteger totalBytesRead = 0;
    
    while (len > 0 && self.currentInput)
    {
        NSInteger bytesRead = [self.currentInput read:buffer maxLength:len];
        DLog(@"     read %d bytes from %@", (int)bytesRead, self.currentInput);
        if (bytesRead > 0)
        {
            // Got some data from the stream:
            totalBytesRead += bytesRead;
            buffer += bytesRead;
            len -= bytesRead;
        }
        else if (bytesRead == 0)
        {
            // At EOF on stream, so go to the next one:
            [self openNextInput];
        }
        else
        {
            // There was a read error:
            [self setErrorFrom:self.currentInput];
            return bytesRead;
        }
    }
    
    return totalBytesRead;
}

// Read enough bytes from the aggregated input to refill my self.buffer. Returns success/failure.
- (BOOL)refillBuffer
{
    DLog(@"   Refilling buffer");
    NSInteger bytesRead = [self read:self.buffer + self.bufferLength maxLength:self.bufferSize - self.bufferLength];
    if (bytesRead <= 0)
    {
        DLog(@"     at end of input, can't refill");
        return NO;
    }
    self.bufferLength += bytesRead;
    DLog(@"   refilled buffer to %u bytes", (unsigned)self.bufferLength);
    //DLog(@"   buffer is now \"%.*s\"", self, self.bufferLength, self.buffer);
    return YES;
}

// Write from my self.buffer to self.output, then refill self.buffer if it's not halfway full.
- (BOOL)writeToOutput
{
    NSAssert(self.bufferLength > 0, @"Buffer length must be greater than zero");
    NSInteger bytesWritten = [self.output write:self.buffer maxLength:self.bufferLength];
    DLog(@"   Wrote %d (of %u) bytes to self.output (total %lld of %lld)", (int)bytesWritten, (unsigned)self.bufferLength, self.totalBytesWritten+bytesWritten, self.length);
    if (bytesWritten <= 0)
    {
        [self setErrorFrom:self.output];
        return NO;
    }
    self.totalBytesWritten += bytesWritten;
    NSAssert(bytesWritten <= (NSInteger)self.bufferLength, @"Wrote more than our buffer length.");
    self.bufferLength -= bytesWritten;
    memmove(self.buffer, self.buffer + bytesWritten, self.bufferLength);
    //DLog(@"     buffer is now \"%.*s\"", self.bufferLength, self.buffer);
    if (self.bufferLength <= self.bufferSize / 2)
    {
        [self refillBuffer];
    }
    
    return self.bufferLength > 0;
}

// Handle an async event on my self.output stream -- basically, write to it when it has room.
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    if (stream != self.output)
    {
        return;
    }
    
    DLog(@"Received event 0x%x", (unsigned)event);
    switch (event)
    {
        case NSStreamEventOpenCompleted:
        {
            if ([self openNextInput])
            {
                [self refillBuffer];
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (self.input && self.input.streamStatus < NSStreamStatusOpen)
            {
                // CFNetwork workaround; see https://github.com/couchbaselabs/TouchDB-iOS/issues/99
                DLog(@"   Input isn't open; waiting...");
                [self performSelector:@selector(retryWrite:) withObject:stream afterDelay:0.001];
            }
            else if (![self writeToOutput])
            {
                DLog(@"   At end -- closing self.output!");
                if (self.totalBytesWritten != self.length && !self.error)
                {
                    DLog(@"[WARN] Wrote %lld bytes, but expected length was %lld!", self.totalBytesWritten, self.length);
                }
                [self close];
            }
            break;
        }
        case NSStreamEventEndEncountered:
        {
            // This means the self.input stream was closed before reading all the data.
            [self close];
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)retryWrite:(NSStream *)stream
{
    [self stream:stream handleEvent:NSStreamEventHasSpaceAvailable];
}

- (NSData *)allOutput
{
    NSOutputStream *output = [NSOutputStream outputStreamToMemory];
    [self openForOutputTo:output];
    
    while (self.isOpen)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    
    return [output propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}


@end