//
//  XMPPFlexibleOffline.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 24/04/16.
//  Copyright © 2016 vms.me. All rights reserved.
//

#import "XMPPModule.h"

extern NSString *const XMPPOfflineNamespace;

@protocol XMPPFlexibleOfflineDelegate <NSObject>
@optional
- (void)xmppFlexibleOfflineDidReceiveNumberOfMessages:(NSUInteger)numberOfMessages;
- (void)xmppFlexibleOfflineDidEndReceivingMessages;
- (void)xmppFlexibleOfflineDidPurgeMessages;

@end

@interface XMPPFlexibleOffline : XMPPModule

- (void)getInfo;
- (void)retrieveAllOfflineMessages;
- (void)purgeAllOfflineMessages;

@end
