//
//  XMPPMessage+Utils.m
//  VMS
//
//  Created by Francesco Cosentino on 13/05/15.
//
//

#import "XMPPMessage+Utils.h"
#import "XMPPFramework.h"

@implementation XMPPMessage (Utils)

- (BOOL)isGroupChatMessageFromSelf
{
	XMPPJID *from = self.from;
	XMPPJID *to = self.to;
	
	if ([self.type isEqualToString:@"groupchat"] && [from.resource isEqualToString:to.user]) {
		return YES;
	}
	
	return NO;
}

- (BOOL)isGroupAffiliationChangeFromSelf
{
	NSXMLElement *x = [self elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"];
	
	if ([self.type isEqualToString:@"normal"] && x) {
		NSXMLElement *item = [x elementForName:@"item"];
		NSString *affiliation = [item attributeStringValueForName:@"affiliation"];
		return affiliation != nil;
	}
	
	return NO;
}

- (BOOL)isNormalMessageFromSelf
{
	if ([self.type isEqualToString:@"normal"] && [self.from.bare isEqualToString:self.to.bare]) {
		return YES;
	}
	
	return NO;
}

- (BOOL)isMuteActorMessage
{
	if ([self.type isEqualToString:@"normal"] && [self elementForName:@"muted_actors"]) {
		return YES;
	}
	return NO;
}

- (BOOL)isUnmuteActorMessage
{
	if ([self.type isEqualToString:@"normal"] && [self elementForName:@"unmuted_actors"]) {
		return YES;
	}
	return NO;
}

- (NSArray*)itemsForMuteActorMessage
{
	if ([self.type isEqualToString:@"normal"]) {
		NSXMLElement *items = [self elementForName:@"muted_actors"];
		return items.children;
	}
	return nil;
}

- (NSArray*)itemsForUnmuteActorMessage
{
	if ([self.type isEqualToString:@"normal"]) {
		NSXMLElement *items = [self elementForName:@"unmuted_actors"];
		return items.children;
	}
	return nil;
}

- (void)forceBody
{
	// add empty body if needed: this is for MAM to save into db
    if (!([self body] != nil && [self body].length > 0)) {
		[self removeElementForName:@"body"];
		[self addBody:@"_"];
	}
}

#pragma mark - Recv receipt

- (BOOL)hasVMSReceivedReceipt
{
	return [self elementForName:@"recv" xmlns:@"vms"] != nil;
}

// @return {"user1": date}
- (NSDictionary*)vmsReceivedReceipts
{
	NSXMLElement *recv = [self elementForName:@"recv" xmlns:@"vms"];
	
	NSMutableDictionary *res = [NSMutableDictionary dictionary];
	NSArray *bys = recv.children;
	for (NSXMLElement *by in bys) {
		NSString *user = [by attributeStringValueForName:@"jid"];
		NSString *ts = [by attributeStringValueForName:@"ts"];
		res[user] = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue]];
	}
	
	return res;
}

#pragma mark - Read receipt

- (BOOL)hasVMSReadReceipt
{
	return [self elementForName:@"read" xmlns:@"vms"] != nil;
}

- (NSDictionary*)vmsReadReceipts
{
	NSXMLElement *recv = [self elementForName:@"read" xmlns:@"vms"];
	
	NSMutableDictionary *res = [NSMutableDictionary dictionary];
	NSArray *bys = recv.children;
	for (NSXMLElement *by in bys) {
		NSString *user = [by attributeStringValueForName:@"jid"];
		NSString *ts = [by attributeStringValueForName:@"ts"];
		res[user] = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue]];
	}
	
	return res;
}

@end
