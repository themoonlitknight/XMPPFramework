//
//  XMPPMessage+Delete.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 01/11/17.
//  Copyright © 2017 vms.me. All rights reserved.
//

#import "XMPPMessage+Delete.h"
#import "NSXMLElement+XMPP.h"

#define kTag		@"deleted_messages"
#define kNamespace 	@"urn:xmpp:vms:delete"

@implementation XMPPMessage (Delete)

- (BOOL)hasDeletedMessages
{
	return [self deletedMessagesElement] != nil;
}

- (NSXMLElement*)deletedMessagesElement
{
	NSXMLElement *elem = [self elementForName:kTag xmlns:kNamespace];
	return elem;
}

- (NSArray<NSString*>*)deletedMessageIDs
{
	NSXMLElement *del = [self deletedMessagesElement];
	NSArray *items = [del elementsForName:@"item"];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:items.count];
	for (NSXMLElement *item in items) {
		[array addObject:[item attributeStringValueForName:@"id"]];
	}
	return array;
}

@end
