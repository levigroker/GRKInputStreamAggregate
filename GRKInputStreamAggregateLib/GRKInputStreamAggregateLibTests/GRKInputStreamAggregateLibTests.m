//
//  GRKInputStreamAggregateTests.m
//  Tests
//
//  Created by Levi Brown on 12/31/15.
//  Copyright © 2015 Levi Brown. All rights reserved.
//
//  Portions copyright (c) 2012-2013 Couchbase, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GRKInputStreamAggregate.h"

#define kExpectedOutputString @"<part the first, let us make it a bit longer for greater interest><2nd part, again unnecessarily prolonged for testing purposes beyond any reasonable length...>"

@interface GRKInputStreamAggregateTests : XCTestCase <NSStreamDelegate>

@property (nonatomic,assign) BOOL finished;
@property (nonatomic,strong) NSInputStream *stream;
@property (nonatomic,strong) NSMutableData *output;

@end

@implementation GRKInputStreamAggregateTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Accessors

- (void)setStream:(NSInputStream *)stream
{
    _finished = NO;
    _stream.delegate = nil;
    _stream = stream;
    _output = [[NSMutableData alloc] init];
    stream.delegate = self;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    XCTAssertEqualObjects(stream, _stream);
    switch (event)
    {
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            uint8_t buffer[10];
            NSInteger length = [_stream read: buffer maxLength: sizeof(buffer)];
            NSLog(@"    read %d bytes", (int)length);
            //Assert(length > 0);
            [_output appendBytes: buffer length: length];
            break;
        }
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            _finished = YES;
            break;
        default:
            XCTAssert(NO, @"Unexpected stream event %d", (int)event);
    }
}

#pragma mark - Helpers

- (GRKInputStreamAggregate *)createWriterWithBufferSize:(unsigned)bufSize
{
    GRKInputStreamAggregate *stream = [[GRKInputStreamAggregate alloc] initWithBufferSize: bufSize];
    [stream addString:@"<part the first, let us make it a bit longer for greater interest>"];
    [stream addString:@"<2nd part, again unnecessarily prolonged for testing purposes beyond any reasonable length...>"];
    XCTAssertEqual(stream.length, (SInt64)kExpectedOutputString.length);
    return stream;
}

- (NSString *)UTF8StringFromData:(NSData *)data
{
    NSString *retVal = nil;
    
    if (data)
    {
        retVal = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return retVal;
}

#pragma mark - Tests

- (void)test_GRKInputStreamAggregate_Sync
{
    for (unsigned bufSize = 1; bufSize < 128; ++bufSize)
    {
        NSLog(@"Buffer size = %u", bufSize);
        GRKInputStreamAggregate *mp = [self createWriterWithBufferSize:bufSize];
        NSData *outputBytes = [mp allOutput];
        XCTAssertEqualObjects([self UTF8StringFromData:outputBytes], kExpectedOutputString);
        // Run it a second time to make sure re-opening works:
        outputBytes = [mp allOutput];
        XCTAssertEqualObjects([self UTF8StringFromData:outputBytes], kExpectedOutputString);
    }
}

- (void)test_GRKInputStreamAggregate_Async
{
    GRKInputStreamAggregate * writer = [self createWriterWithBufferSize:64];
    NSInputStream *input = [writer openForInputStream];
    XCTAssert(input);
    [self setStream: input];
    
    NSRunLoop *rl = [NSRunLoop currentRunLoop];
    [input scheduleInRunLoop: rl forMode: NSDefaultRunLoopMode];
    NSLog(@"Opening stream");
    [input open];

    while (!_finished) {
        NSLog(@"...waiting for stream...");
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    }
    
    [input removeFromRunLoop: rl forMode: NSDefaultRunLoopMode];
    NSLog(@"Closing stream");
    [input close];
    [writer close];
    XCTAssertEqualObjects([self UTF8StringFromData:_output], kExpectedOutputString);
}

- (void)test_GRKInputStreamAggregate_Async1 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async2 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async3 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async4 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async5 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async6 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async7 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async8 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async9 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async10 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async11 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async12 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async13 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async14 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async15 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async16 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async17 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async18 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async19 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async20 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async21 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async22 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async23 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async24 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async25 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async26 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async27 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async28 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async29 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async30 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async31 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async32 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async33 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async34 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async35 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async36 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async37 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async38 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async39 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async40 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async41 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async42 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async43 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async44 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async45 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async46 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async47 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async48 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async49 {
    [self test_GRKInputStreamAggregate_Async];
}

- (void)test_GRKInputStreamAggregate_Async50 {
    [self test_GRKInputStreamAggregate_Async];
}

@end
