#import <Foundation/Foundation.h>

#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>

typedef void (^serviceCallback)(NSString* result, NSMutableArray* array);

@interface serviceDiscovery
- (void)getNetworkServices: (serviceCallback) callback;
@end