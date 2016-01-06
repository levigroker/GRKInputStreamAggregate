//
//  GRKInputStreamAggregate.h
//
//  Modified from CBLMultiStreamWriter.h, created by Jens Alfke on 2/3/12.
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

#import <Foundation/Foundation.h>

/**
 * The default buffer size for the stream.
 */
extern NSUInteger const kGRKInputStreamAggregateDefaultBufferSize;

/**
 * A stream aggregator that reads from a concatenated sequence of other inputs.
 * Use this to combine multiple input streams (and data blobs) together into one.
 * This is useful when uploading multipart MIME bodies.
 */
@interface GRKInputStreamAggregate : NSObject
{
    @protected
    SInt64 _length;
    SInt64 _totalBytesWritten;
}

/**
 * Total length of the aggregated stream.
 * This is just computed by adding the values passed to -addStream:length:, and the lengths of the NSData objects and files added.
 * If -addStream: has been called (the version without length:) the length is unknown and will be returned as -1.
 * (Many clients won't care about the length, but CBLMultipartUploader does.)
 */
@property (readonly,assign) SInt64 length;

/**
 * Has this agregate been opened for reading or writing?
 */
@property (readonly) BOOL isOpen;

/**
 * Populated if there is an error while reading from or writing to the related streams.
 */
@property (readonly,strong) NSError *error;

/**
 * Initializer which takes a stream buffer size.
 * Use this if you want to override the default buffer size (used by the `init` method).
 *
 * @param bufferSize The size, in bytes, of the buffer to allocate for the stream.
 *
 * @return An initialized GRKInputStreamAggregate with the given buffer size.
 *
 * @see kGRKInputStreamAggregateDefaultBufferSize;
 */
- (instancetype)initWithBufferSize:(NSUInteger)bufferSize NS_DESIGNATED_INITIALIZER;

- (void) addStream:(NSInputStream *)stream length:(UInt64)length;
- (void) addStream:(NSInputStream *)stream;
- (void) addData:(NSData *)data;
- (void) addString:(NSString *)string;
- (BOOL) addFileURL:(NSURL *)fileURL;
- (BOOL) addFile:(NSString *)path;

/**
 * Returns an input stream; reading from this will return the contents of all added streams in sequence.
 * This stream can be set as the HTTPBodyStream of an NSURLRequest.
 * It is the caller's responsibility to close the returned stream.
 * @see close
 */
- (NSInputStream *)openForInputStream;

/**
 * Closes and cleans up the resources used to populate the input stream.
 * This should be called once reading from the input stream has finished.
 * @see openForInputStream
 */
- (void)close;

/**
 * Associates an output stream; the data from all of the added streams will be written to the output, asynchronously.
 * Once all aggregated content has been written to the given output stream (or an error occurs), `close` will be called automatically,
 * so there is no need to call `close` manually when using this method.
 *
 * @param output The output stream to write to.
 */
- (void)openForOutputTo:(NSOutputStream *)output;

/**
 * Convenience method that opens an output stream, collects all the data, and returns it.
 *
 * @return All aggregated inputs as a data object.
 */
- (NSData *)allOutput;

// protected:
- (void)addInput:(id)input length:(UInt64)length;
- (void)opened;

@end