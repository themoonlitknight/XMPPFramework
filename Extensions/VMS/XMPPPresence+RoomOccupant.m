//
//  XMPPPresence+RoomOccupant.m
//  VMS
//
//  Created by Francesco Cosentino on 19/03/15.
//
//

#import "XMPPPresence+RoomOccupant.h"
#import "NSXMLElement+XMPP.h"

@implementation XMPPPresence (RoomOccupant)

- (NSString*)vms_occupantFullJIDString
{
	NSString *jid;
	NSXMLElement *x = [self elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"];
	if (x) {
		NSXMLElement *item = [x elementForName:@"item"];
		if (item) {
			jid = [item attributeStringValueForName:@"jid"];
		}
	}
	return jid;
}

- (BOOL)vms_occupantIsOwner
{
	NSXMLElement *item = [self elementForName:@"item"];
	if (item) {
		NSString *affiliation = [item attributeStringValueForName:@"affiliation"];
		return [affiliation isEqualToString:@"owner"];
	}
	return NO;
}

- (NSString*)RO_fullJIDString
{
	NSString *jid;
	NSXMLElement *x = [self elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"];
	if (x) {
		NSXMLElement *item = [x elementForName:@"item"];
		if (item) {
			jid = [item attributeStringValueForName:@"jid"];
		}
	}
	return jid;
}

- (BOOL)RO_isOwner
{
	NSXMLElement *item = [self elementForName:@"item"];
	if (item) {
		NSString *role = [item attributeStringValueForName:@"role"];
		return [role isEqualToString:@"owner"];
	}
	return NO;
}

@end
