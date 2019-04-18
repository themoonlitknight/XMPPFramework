//
//  XMPPFlexibleOffline.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 24/04/16.
//  Copyright © 2016 vms.me. All rights reserved.
//

#import "XMPPFlexibleOffline.h"
#import "XMPPFramework.h"
#import "XMPPLogging.h"
#import "XMPPConstants.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

NSString *const XMPPOfflineNamespace = @"http://jabber.org/protocol/offline";

@interface XMPPFlexibleOffline () <XMPPStreamDelegate>
{
	NSString *_currentFetchID;
	NSString *_currentPurgeID;
}

@end

@implementation XMPPFlexibleOffline

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue
{
	if ((self = [super initWithDispatchQueue:queue])) {
		
	}
	return self;
}

#pragma mark - Public methods

- (void)getInfo
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPDiscoInfoNamespace];
		[query addAttributeWithName:@"node" stringValue:XMPPOfflineNamespace];
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:nil child:query];
		
		[xmppStream sendElement:iq];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)retrieveAllOfflineMessages
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		if (_currentFetchID != nil) {
			// stop if another fetch is in progress
			return;
		}
		
		_currentFetchID = [xmppStream generateUUID];
		
		NSXMLElement *offline = [NSXMLElement elementWithName:@"offline" xmlns:XMPPOfflineNamespace];
		[offline addChild:[NSXMLElement elementWithName:@"fetch"]];
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:_currentFetchID child:offline];
		
		[xmppStream sendElement:iq];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)purgeAllOfflineMessages
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		if (_currentFetchID != nil || _currentPurgeID != nil) {
			// stop if another fetch is in progress
			// stop if another purge is in progress
			return;
		}
		
		_currentPurgeID = [xmppStream generateUUID];
		
		NSXMLElement *offline = [NSXMLElement elementWithName:@"offline" xmlns:XMPPOfflineNamespace];
		[offline addChild:[NSXMLElement elementWithName:@"purge"]];
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:_currentPurgeID child:offline];
		
		[xmppStream sendElement:iq];
	}};
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
	if ([iq.elementID isEqualToString:_currentFetchID]) {
		_currentFetchID = nil;
	}
	else if ([iq.elementID isEqualToString:_currentPurgeID]) {
		_currentPurgeID = nil;
	}
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	if ([iq.type isEqualToString:@"result"]) {
		if ([iq.elementID isEqualToString:_currentFetchID]) {
			// finished receiving offline messages
			[multicastDelegate xmppFlexibleOfflineDidEndReceivingMessages];
			_currentFetchID = nil;
			return NO;
		}
		
		else if ([iq.elementID isEqualToString:_currentPurgeID]) {
			// messages have been purged
			[multicastDelegate xmppFlexibleOfflineDidPurgeMessages];
			_currentPurgeID = nil;
			return NO;
		}
		
		
		NSXMLElement *query;
		
		// disco#info
		query = [iq elementForName:@"query" xmlns:XMPPDiscoInfoNamespace];
		if ([[query attributeStringValueForName:@"node"] isEqualToString:XMPPOfflineNamespace]) {
			NSXMLElement *x = [query elementForName:@"x" xmlns:@"jabber:x:data"];
			for (NSXMLElement *field in [x elementsForName:@"field"]) {
				if ([[field attributeStringValueForName:@"var"] isEqualToString:@"number_of_messages"]) {
					// number of messages
					NSXMLElement *value = [field elementForName:@"value"];
					if (value) {
						NSUInteger numberOfMessages = [value stringValueAsNSUInteger];
						[multicastDelegate xmppFlexibleOfflineDidReceiveNumberOfMessages:numberOfMessages];
						return NO;
					}
				}
			}
			return NO;
		}
	}
	
	return NO;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	_currentFetchID = nil;
	_currentPurgeID = nil;
}

@end
