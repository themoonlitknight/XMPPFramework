#import "XMPPMessage+XEP0045.h"
#import "NSXMLElement+XMPP.h"


@implementation XMPPMessage(XEP0045)

- (BOOL)isGroupChatMessage
{
	return [[[self attributeForName:@"type"] stringValue] isEqualToString:@"groupchat"];
}

- (BOOL)isGroupChatMessageWithBody
{
	if ([self isGroupChatMessage])
	{
		NSString *body = [[self elementForName:@"body"] stringValue];
		
		return ([body length] > 0);
	}
	
	return NO;
}

- (BOOL)isGroupChatMessageWithSubject
{
    if ([self isGroupChatMessage])
	{
        NSString *subject = [[self elementForName:@"subject"] stringValue];

		return ([subject length] > 0);
    }

    return NO;
}

- (int)configurationChangeForGroupChatMessage
{
	if ([self isGroupChatMessage]) {
		NSXMLElement *x = [self elementForName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"];
		if (x) {
			int code = [[x elementForName:@"status"] attributeIntValueForName:@"code"];
			switch (code) {
				case 104:
				case 170:
				case 171:
				case 172:
				case 173:
					return code;
				
				default:
					return -1;
			}
		}
	}
	
	return -1;
}

@end
