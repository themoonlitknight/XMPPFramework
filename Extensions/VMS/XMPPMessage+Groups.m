//
//  XMPPMessage+Groups.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 15/10/2019.
//

#import "XMPPMessage+Groups.h"

@implementation XMPPMessage (Groups)

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
