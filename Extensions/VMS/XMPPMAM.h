//
//  XMPPMAM.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 28/08/15.
//  Copyright (c) 2015 vms.me. All rights reserved.
//

#import "XMPPModule.h"

@class XMPPMessage;
@class XMPPIDTracker;
@class XMPPIQ;

extern NSString *const XMPPMAMNamespace;

@interface XMPPMAM : XMPPModule
{
	XMPPIDTracker *responseTracker;
}

- (NSString*)fetchMessagesWithJID:(NSString*)jid startDate:(NSDate*)startDate endDate:(NSDate*)endDate limit:(int)limit bookmark:(NSString*)bookmark;

- (NSString*)fetchMUCMessagesWithJID:(NSString*)jid startDate:(NSDate*)startDate endDate:(NSDate*)endDate limit:(int)limit bookmark:(NSString*)bookmark;

@end


@protocol XMPPMAMDelegate <NSObject>
@optional

- (void)xmppMAM:(XMPPMAM*)sender didReceiveMessage:(XMPPMessage*)message;
- (void)xmppMAM:(XMPPMAM*)sender didEndPageWithMore:(BOOL)more last:(NSString*)lastID;
- (void)xmppMAM:(XMPPMAM*)sender didFailWithToReceiveMessages:(XMPPIQ*)iq;

@end
