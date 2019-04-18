//
//  XMPPMessage+VMSXEP_ChatStateExtended.h
//  VMS
//
//  Created by Francesco Cosentino on 06/03/15.
//
//

#import "XMPPMessage.h"

@interface XMPPMessage (VMSXEP_ChatStateExtended)

- (void)addComposingTypeChatState:(NSString *)type;
- (NSString*)composingTypeChatState;

@end
