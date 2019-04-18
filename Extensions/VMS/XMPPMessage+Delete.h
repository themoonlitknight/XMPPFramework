//
//  XMPPMessage+Delete.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 01/11/17.
//  Copyright © 2017 vms.me. All rights reserved.
//

#import "XMPPMessage.h"

@interface XMPPMessage (Delete)

- (BOOL)hasDeletedMessages;
- (NSArray<NSString*>*)deletedMessageIDs;

@end
