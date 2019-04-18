//
//  XMPPMessage+XEP0313.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 31/08/15.
//  Copyright (c) 2015 vms.me. All rights reserved.
//

#import "XMPPMessage+XEP0313.h"
#import "NSXMLElement+XMPP.h"

@implementation XMPPMessage (XEP0313)

- (BOOL)hasMAMMessage
{
	NSXMLElement *element;
	
	element = [self elementForName:@"result"];
	if (element) {
		element = [element elementForName:@"forwarded"];
		if (element) {
			element = [element elementForName:@"message"];
			if (element) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (BOOL)isMAMEndResults
{
	NSXMLElement *element;
	
	element = [self elementForName:@"fin"];
	if (element) {
		return YES;
	}
	
	return NO;
}

- (XMPPMessage*)mamMessage
{
	NSXMLElement *m = [[[self elementForName:@"result"] elementForName:@"forwarded"] elementForName:@"message"];
	return [XMPPMessage messageFromElement:m];
}

- (NSString*)mamQueryID
{
	if ([self hasMAMMessage]) {
		NSXMLElement *result = [self elementForName:@"result"];
		NSString *queryID = [[result attributeForName:@"queryid"] stringValue];
		return queryID;
	}
	else if ([self isMAMEndResults]) {
		NSXMLElement *fin = [self elementForName:@"fin"];
		NSString *queryID = [[fin attributeForName:@"queryid"] stringValue];
		return queryID;
	}
	
	return nil;
}

- (BOOL)mamIsComplete
{
	if ([self isMAMEndResults]) {
		NSXMLElement *fin = [self elementForName:@"fin"];
		BOOL complete = [fin attributeBoolValueForName:@"complete"];
		return complete;
	}
	
	return NO;
}

- (NSString*)mamFirstMessageID
{
	if (![self mamIsComplete]) {
		NSXMLElement *fin = [self elementForName:@"fin"];
		if (fin) {
			NSXMLElement *set = [fin elementForName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
			NSString *first = [[set elementForName:@"first"] stringValue];
			return first;
		}
	}
	
	return nil;
}

- (NSString*)mamLastMessageID
{
	if (![self mamIsComplete]) {
		NSXMLElement *fin = [self elementForName:@"fin"];
		if (fin) {
			NSXMLElement *set = [fin elementForName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
			NSString *last = [[set elementForName:@"last"] stringValue];
			return last;
		}
	}
	
	return nil;
}

@end
