//
//  XMPPMessage+VMSXEP_ReceiptExtended.h
//  VMS
//
//  Created by Francesco Cosentino on 06/03/15.
//
//

#import "XMPPMessage.h"

@interface XMPPMessage (VMSXEP_ReceiptExtended)

+ (XMPPMessage *)generateReceiptResponseWithRecipient:(NSString*)jidString messageID:(NSString*)messageID;

- (BOOL)hasAckReceiptResponse;
- (NSString *)ackReceiptResponseID;
+ (XMPPMessage *)generateAckResponseWithRecipient:(NSString*)jidString messageID:(NSString*)messageID;

@end
