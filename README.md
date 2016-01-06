GRKInputStreamAggregate
===========
[![Build Status](https://travis-ci.org/levigroker/GRKInputStreamAggregate.svg)](https://travis-ci.org/levigroker/GRKInputStreamAggregate)
[![Version](http://img.shields.io/cocoapods/v/GRKInputStreamAggregate.svg)](http://cocoapods.org/?q=GRKInputStreamAggregate)
[![Platform](http://img.shields.io/cocoapods/p/GRKInputStreamAggregate.svg)]()
[![License](http://img.shields.io/cocoapods/l/GRKInputStreamAggregate.svg)](https://github.com/levigroker/GRKInputStreamAggregate/blob/master/LICENSE.txt)

A stream aggregator that reads from a concatenated sequence of other inputs. Use this to
combine multiple input streams (and data blobs) together into one. This is useful when
uploading multipart MIME bodies.

### Installing

If you're using [CocoPods](http://cocopods.org) it's as simple as adding this to your
`Podfile`:

	pod 'GRKInputStreamAggregate'

otherwise, simply add the contents of the `GRKInputStreamAggregate` subdirectory to your
project.

### Documentation

As an example, the aggregate can be used to provide a concatenated stream for a multipart
file upload.

To do this, one would create a `NSURLSessionUploadTask` via `NSURLSession`s `uploadTaskWithStreamedRequest:` method.  
Example:

		NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
		[urlRequest setHTTPMethod:@"POST"];
		[urlRequest setValue: [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];

		NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:self delegateQueue:nil];

		NSURLSessionUploadTask *uploadTask = [urlSession uploadTaskWithStreamedRequest:urlRequest];

Then, implement the task delegate method `URLSession:task:needNewBodyStream:`.  
Example:

		- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
		{
			NSString *fileName = [self.fileURL lastPathComponent];

			//Ensure any previous aggregate gets closed
			[self.aggregate close];
	
			//Create a new aggregate for the body stream
			GRKInputStreamAggregate *aggregate = [[GRKInputStreamAggregate alloc] init];

			//Build our body stream by aggregating the multipart boundaries with our file.
			[aggregate addString:[NSString stringWithFormat:@"--%@\r\n", kMultipartFormBoundary]];
			[aggregate addString:[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", kMultipartFormFileInput, fileName]];
			[aggregate addFileURL:self.fileURL];
			[aggregate addString:[NSString stringWithFormat:@"\r\n--%@--\r\n", kMultipartFormBoundary]];

			self.aggregate = aggregate;
	
			NSInputStream *inputStream = [aggregate openForInputStream];

			completionHandler(inputStream);
		}

...and be sure to `close` the aggregate when done, in the `URLSession:task:didCompleteWithError:`
delegate method.  
Example:

		- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
		{
			//Ensure any previous aggregate gets closed
			[self.aggregate close];
		}

#### Disclaimer and Licence

* This derivative work is based on work from the [Couchbase Lite iOS](https://github.com/couchbase/couchbase-lite-ios) project.
  Specifically the `CBLMultiStreamWriter` class, created by Jens Alfke of [Couchbase](http://www.couchbase.com).
  Neither Couchbase nor Jens Alfke endorse me (Levi Brown) or this derivative work.
  Please see the license file `./GRKInputStreamAggregate/LICENSE.txt`
* This work is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
  Please see the included LICENSE.txt for complete details.

#### About
A professional iOS engineer by day, my name is Levi Brown. Authoring a blog
[grokin.gs](http://grokin.gs), I am reachable via:

Twitter [@levigroker](https://twitter.com/levigroker)  
Email [levigroker@gmail.com](mailto:levigroker@gmail.com)  

Your constructive comments and feedback are always welcome.
