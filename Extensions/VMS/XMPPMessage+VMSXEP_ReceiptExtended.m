//
//  XMPPMessage+VMSXEP_ReceiptExtended.m
//  VMS
//
//  Created by Francesco Cosentino on 06/03/15.
//
//

#import "XMPPMessage+VMSXEP_ReceiptExtended.h"
#import "NSXMLElement+XMPP.h"

static NSString *const xmlns_receiptext = @"urn:xmpp:vms-receiptext";

@implementation XMPPMessage (VMSXEP_ReceiptExtended)

#pragma mark - Received receipt

+ (XMPPMessage*)generateReceiptResponseWithRecipient:(NSString *)jidString messageID:(NSString *)messageID
{
	// Example:
	//
	// <message to="juliet">
	//   <received xmlns="urn:xmpp:receipts" id="ABC-123"/>
	// </message>
	
	NSXMLElement *received = [NSXMLElement elementWithName:@"received" xmlns:@"urn:xmpp:receipts"];
	
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    [message addAttributeWithName:@"id" stringValue:[[NSUUID UUID] UUIDString]];
	
	NSString *to = jidString;
	if (to)
	{
		[message addAttributeWithName:@"to" stringValue:to];
	}
	
	NSString *msgid = messageID;
	if (msgid)
	{
		[received addAttributeWithName:@"id" stringValue:msgid];
	}
	
	[message addChild:received];
	
	return [[self class] messageFromElement:message];
}

#pragma mark - Ack receipt

- (BOOL)hasAckReceiptResponse
{
	NSXMLElement *receiptResponse = [self elementForName:@"ack" xmlns:xmlns_receiptext];
	
	return (receiptResponse != nil);
}

- (NSString *)ackReceiptResponseID
{
	NSXMLElement *receiptResponse = [self elementForName:@"ack" xmlns:xmlns_receiptext];
	
	return [receiptResponse attributeStringValueForName:@"id"];
}

+ (XMPPMessage *)generateAckResponseWithRecipient:(NSString*)jidString messageID:(NSString*)messageID
{
	// Example:
	//
	// <message to="juliet">
	//   <ack xmlns="urn:xmpp:vms-receiptext" id="ABC-123"/>
	// </message>
	
    if (!(jidString && jidString.length > 0) ||
        !(messageID && messageID.length > 0)) {
		return nil;
	}
	
	NSXMLElement *received = [NSXMLElement elementWithName:@"ack" xmlns:xmlns_receiptext];
	
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    [message addAttributeWithName:@"id" stringValue:[[NSUUID UUID] UUIDString]];
	
	[message addAttributeWithName:@"to" stringValue:jidString];
	
	[received addAttributeWithName:@"id" stringValue:messageID];
	
	[message addChild:received];
	
	return [[self class] messageFromElement:message];
}

@end
