//
//  XMPPMAM.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 28/08/15.
//  Copyright (c) 2015 vms.me. All rights reserved.
//

#import "XMPPMAM.h"
#import "XMPPMessage+XEP0313.h"
#import "XMPPIDTracker.h"
#import "XMPPFramework.h"
#import "XMPPLogging.h"
#import "NSXMLElement+XEP_0297.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

NSString *const XMPPMAMNamespace = @"urn:xmpp:mam:1";

@interface XMPPMAM () <XMPPStreamDelegate>

@property (nonatomic) NSString *queryID;

@end

@implementation XMPPMAM

- (BOOL)activate:(XMPPStream *)aXmppStream
{
	if ([super activate:aXmppStream])
	{
		responseTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	XMPPLogTrace();
	
	dispatch_block_t block = ^{ @autoreleasepool {

		[responseTracker removeAllIDs];
		responseTracker = nil;
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	[super deactivate];
}

- (NSString*)fetchMessagesWithJID:(NSString*)jid startDate:(NSDate*)startDate endDate:(NSDate*)endDate limit:(int)limit bookmark:(NSString*)bookmark
{
	self.queryID = [xmppStream generateUUID];
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMAMNamespace];
		[query addAttributeWithName:@"queryid" stringValue:self.queryID];
		
		// x
		NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
		[x addAttributeWithName:@"type" stringValue:@"submit"];
		[query addChild:x];
		
		// field: FORM_TYPE
		NSXMLElement *fieldFormType = [NSXMLElement elementWithName:@"field"];
		[fieldFormType addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
		[fieldFormType addAttributeWithName:@"type" stringValue:@"hidden"];
		[fieldFormType addChild:[NSXMLElement elementWithName:@"value" stringValue:@"url:xmpp:mam:1"]];
		[x addChild:fieldFormType];
		
		if (jid) {
			// field: with
			NSXMLElement *fieldWith = [NSXMLElement elementWithName:@"field"];
			[fieldWith addAttributeWithName:@"var" stringValue:@"with"];
			[fieldWith addChild:[NSXMLElement elementWithName:@"value" stringValue:[[XMPPJID jidWithString:jid] bare]]];
			[x addChild:fieldWith];
		}
		
		if (startDate) {
			// field: start
			NSXMLElement *fieldStart = [NSXMLElement elementWithName:@"field"];
			[fieldStart addAttributeWithName:@"var" stringValue:@"start"];
			[fieldStart addChild:[NSXMLElement elementWithName:@"value" stringValue:[self getUTCFormattedDate:startDate]]];
			[x addChild:fieldStart];
		}
		
		if (endDate) {
			// field: end
			NSXMLElement *fieldEnd = [NSXMLElement elementWithName:@"field"];
			[fieldEnd addAttributeWithName:@"var" stringValue:@"end"];
			[fieldEnd addChild:[NSXMLElement elementWithName:@"value" stringValue:[self getUTCFormattedDate:endDate]]];
			[x addChild:fieldEnd];
		}
		
		NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
		[query addChild:set];
		if (limit > 0) {
			[set addChild:[NSXMLElement elementWithName:@"max" numberValue:@(limit)]];
		}
		if (bookmark) {
			[set addChild:[NSXMLElement elementWithName:@"before" stringValue:bookmark]];
		}
		else {
			[set addChild:[NSXMLElement elementWithName:@"before"]];
		}
		
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:[xmppStream generateUUID] child:query];
		
		[xmppStream sendElement:iq];
		
		[responseTracker addID:self.queryID
						target:self
					  selector:@selector(handleMessageArchiveIQ:withInfo:)
					   timeout:60.0];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
	
	return self.queryID;
}

- (NSString*)fetchMUCMessagesWithJID:(NSString*)jid startDate:(NSDate*)startDate endDate:(NSDate*)endDate limit:(int)limit bookmark:(NSString*)bookmark
{
	self.queryID = [xmppStream generateUUID];
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMAMNamespace];
		[query addAttributeWithName:@"queryid" stringValue:self.queryID];
		
		// x
		NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
		[x addAttributeWithName:@"type" stringValue:@"submit"];
		[query addChild:x];
		
		// field: FORM_TYPE
		NSXMLElement *fieldFormType = [NSXMLElement elementWithName:@"field"];
		[fieldFormType addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
		[fieldFormType addAttributeWithName:@"type" stringValue:@"hidden"];
		[fieldFormType addChild:[NSXMLElement elementWithName:@"value" stringValue:@"url:xmpp:mam:1"]];
		[x addChild:fieldFormType];
		
		if (startDate) {
			// field: start
			NSXMLElement *fieldStart = [NSXMLElement elementWithName:@"field"];
			[fieldStart addAttributeWithName:@"var" stringValue:@"start"];
			[fieldStart addChild:[NSXMLElement elementWithName:@"value" stringValue:[self getUTCFormattedDate:startDate]]];
			[x addChild:fieldStart];
		}
		
		if (endDate) {
			// field: end
			NSXMLElement *fieldEnd = [NSXMLElement elementWithName:@"field"];
			[fieldEnd addAttributeWithName:@"var" stringValue:@"end"];
			[fieldEnd addChild:[NSXMLElement elementWithName:@"value" stringValue:[self getUTCFormattedDate:endDate]]];
			[x addChild:fieldEnd];
		}
		
		NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
		[query addChild:set];
		if (limit > 0) {
			[set addChild:[NSXMLElement elementWithName:@"max" numberValue:@(limit)]];
		}
		if (bookmark) {
			[set addChild:[NSXMLElement elementWithName:@"before" stringValue:bookmark]];
		}
		else {
			[set addChild:[NSXMLElement elementWithName:@"before"]];
		}
		
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:[[XMPPJID jidWithString:jid] bareJID] elementID:[xmppStream generateUUID] child:query];
		
		[xmppStream sendElement:iq];
		
		[responseTracker addID:self.queryID
						target:self
					  selector:@selector(handleMessageArchiveIQ:withInfo:)
					   timeout:60.0];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
	
	return self.queryID;
}

- (void)handleMessageArchiveIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)trackerInfo
{
	if ([[iq type] isEqualToString:@"result"]) {
		NSXMLElement *fin = [iq elementForName:@"fin" xmlns:XMPPMAMNamespace];
		NSXMLElement *set = [fin elementForName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
		
		BOOL complete = [fin attributeBoolValueForName:@"complete"];
		NSString *last = [[set elementForName:@"last"] stringValue];
		
		[multicastDelegate xmppMAM:self didEndPageWithMore:!complete last:last];
	} else {
		[multicastDelegate xmppMAM:self didFailWithToReceiveMessages:iq];
	}
}

#pragma mark - XMPPStreamDelegate

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	NSString *type = [iq type];
	if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"]) {
		NSXMLElement *fin = [iq elementForName:@"fin" xmlns:XMPPMAMNamespace];
		if (fin) {
			NSString *queryID = [fin attributeStringValueForName:@"queryid"];
			if ([queryID isEqualToString:self.queryID]) {
				return [responseTracker invokeForID:queryID withObject:iq];
			}
		}
	}
	
	return NO;
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	NSXMLElement *result = [message elementForName:@"result" xmlns:XMPPMAMNamespace];
	BOOL forwarded = [result hasForwardedStanza];
	
	NSString *queryID = [result attributeForName:@"queryid"].stringValue;
	
	if (forwarded && [queryID isEqualToString:self.queryID]) {
		[multicastDelegate xmppMAM:self didReceiveMessage:message];
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	[responseTracker removeAllIDs];
}

#pragma mark - utils

- (NSString *)getUTCFormattedDate:(NSDate *)localDate
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	[dateFormatter setTimeZone:timeZone];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	NSString *dateString = [dateFormatter stringFromDate:localDate];
	return dateString;
}

@end
