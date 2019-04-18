//
//  XMPPMessage+VMSXEP_ChatStateExtended.m
//  VMS
//
//  Created by Francesco Cosentino on 06/03/15.
//
//

#import "XMPPMessage+VMSXEP_ChatStateExtended.h"
#import "NSXMLElement+XMPP.h"

static NSString *const xmlns_chatstates = @"http://jabber.org/protocol/chatstates";

@implementation XMPPMessage (VMSXEP_ChatStateExtended)

- (void)addComposingTypeChatState:(NSString *)type
{
	NSXMLElement *composing = [self elementForName:@"composing" xmlns:xmlns_chatstates];
	[composing addAttributeWithName:@"composing-type" stringValue:type];
}

- (NSString*)composingTypeChatState
{
	NSXMLElement *composing = [self elementForName:@"composing" xmlns:xmlns_chatstates];
	if (composing) {
		NSString *composingType = [composing attributeStringValueForName:@"composing-type"];
		return composingType;
	}
	return nil;
}

@end
