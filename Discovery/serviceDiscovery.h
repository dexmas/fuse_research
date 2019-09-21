#import <Foundation/Foundation.h>

#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>

typedef void (^serviceCallback)(NSString* list);

@interface serviceDiscovery : NSObject
- (instancetype)initWith: (serviceCallback) callback;
- (void)search: (NSString*)services;
@end