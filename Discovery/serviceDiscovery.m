#import "serviceDiscovery.h"

NSMutableArray *serviceArr;
serviceCallback Callback;

@implementation serviceDiscovery

- (instancetype)initWith: (serviceCallback) callback
{
    Callback = callback;
    self = [super init];
    return self;
}
/*
 * Does a service discovery for the given service type. Returns an array of
 * all the services discovered.
 */
- (void)search: (NSString*)services
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
    NSString* result = nil;
    if (services == nil)
    {
        result = @"service not provided";
    }
    else
    {
        serviceArr = [[NSMutableArray alloc] init];

        // Open a socket
        int sd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (sd <= 0) 
        {
            NSLog(@"Error: Could not open socket");
            result = @"TX socket creation failed";
        }
        else 
        {
            // Set socket options
            int broadcastEnable = 1;
            int ret = setsockopt(sd, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));
            if (ret) {
                NSLog(@"Error: setsockopt failed to enable broadcast mode");
                result = @"TX socket setsockopt failed";
                close(sd);
            }
            else 
            {
                // Configure the broadcast IP and port
                struct sockaddr_in broadcastAddr;
                memset(&broadcastAddr, 0, sizeof broadcastAddr);
                broadcastAddr.sin_family = AF_INET;
                inet_pton(AF_INET, "239.255.255.250", &broadcastAddr.sin_addr);
                broadcastAddr.sin_port = htons(1900);

                // Send the broadcast request for the given service type
                NSString *request = [[@"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nST: " stringByAppendingString:services] stringByAppendingString:@"\r\nMX: 2\r\n\r\n"];
                char *requestStr = [request UTF8String];

                ret = sendto(sd, requestStr, strlen(requestStr), 0, (struct sockaddr*)&broadcastAddr, sizeof broadcastAddr);
                if (ret < 0) 
                {
                    NSLog(@"Error: Could not send broadcast");
                    result = @"sendto failed";
                    close(sd);
                }
                else 
                {
                    NSLog(@"ret:%d", ret);
                    NSLog(@"Bcast msg sent");
                    NSLog(@"recv: On to listening");

                    // set timeout to 2 seconds.
                    struct timeval timeV;
                    timeV.tv_sec = 2;
                    timeV.tv_usec = 0;

                    if (setsockopt(sd, SOL_SOCKET, SO_RCVTIMEO, &timeV, sizeof(timeV)) == -1) 
                    {
                        NSLog(@"Error: listenForPackets - setsockopt failed");
                        result = @"RX socket setsockopt failed";
                        close(sd);
                    }
                    else 
                    {
                        NSLog(@"recv: socketopt set");

                        struct sockaddr_in receiveSockaddr;
                        socklen_t receiveSockaddrLen = sizeof(receiveSockaddr);
    
                        size_t bufSize = 9216;
                        void *buf = malloc(bufSize);
                        NSLog(@"recv: listening now: %d", sd);

                        // Keep listening till the socket timeout event occurs
                        while (true)
                        {
                            ssize_t result = recvfrom(sd, buf, bufSize, 0,
                                                        (struct sockaddr *)&receiveSockaddr,
                                                        (socklen_t *)&receiveSockaddrLen);
                            if (result < 0)
                            {
                                NSLog(@"timeup");
                                break;
                            }

                            NSData *data = nil;
                            data = [NSData dataWithBytesNoCopy:buf length:result freeWhenDone:NO];

                            NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            [self processResponse:msg];
                        }

                        free(buf);
                        close(sd);
                    }
                }
            }
        }

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serviceArr options:0 error:nil];
        Callback([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    }});
}

/*
 * Processes the response received from a UPnP device.
 * Converts the string response to a NSMutableDictionary.
 */
- (void)processResponse:(NSString *)message
{
    NSArray *msgLines = [message componentsSeparatedByString:@"\r"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < [msgLines count]; i++)
    {
        NSRange range = [msgLines[i] rangeOfString:@":"];

        if(range.length == 1)
        {
            NSRange p1range = NSMakeRange(0, range.location);
            NSString *part1 = [msgLines[i] substringWithRange:p1range];
            part1 = [part1 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSRange p2range = NSMakeRange(range.location + 1 , [msgLines[i] length] - range.location - 1);
            NSString *part2 = [msgLines[i] substringWithRange:p2range];
            part2 = [part2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            data[part1] = part2;
        }
    }

    NSURL *url = [NSURL URLWithString: data["LOCATION"]];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * rdata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (response != nil) {
        data[@"xml"] = [[NSString alloc] initWithData: rdata encoding:NSUTF8StringEncoding];
        [serviceArr addObject: data];
    } else
        NSLog(@"Error during fetch discovered XML data");
}

@end