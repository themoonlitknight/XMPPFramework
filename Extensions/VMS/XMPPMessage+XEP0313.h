//
//  XMPPMessage+XEP0313.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 31/08/15.
//  Copyright (c) 2015 vms.me. All rights reserved.
//

#import "XMPPMessage.h"

@interface XMPPMessage (XEP0313)

- (BOOL)hasMAMMessage;
- (BOOL)isMAMEndResults;
- (XMPPMessage*)mamMessage;
- (NSString*)mamQueryID;
- (BOOL)mamIsComplete;
- (NSString*)mamFirstMessageID;
- (NSString*)mamLastMessageID;

@end
