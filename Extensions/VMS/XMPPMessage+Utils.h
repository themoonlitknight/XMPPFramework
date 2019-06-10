//
//  XMPPMessage+Utils.h
//  VMS
//
//  Created by Francesco Cosentino on 13/05/15.
//
//

#import "XMPPMessage.h"

@interface XMPPMessage (Utils)

- (BOOL)isGroupChatMessageFromSelf;
- (BOOL)isGroupAffiliationChangeFromSelf;
- (BOOL)isNormalMessageFromSelf;
- (BOOL)isMuteActorMessage;
- (BOOL)isUnmuteActorMessage;
- (NSArray*)itemsForMuteActorMessage;
- (NSArray*)itemsForUnmuteActorMessage;
- (void)forceBody;

- (BOOL)hasVMSReceivedReceipt;
- (NSDictionary<NSString*, NSDate*>*)vmsReceivedReceipts;
- (BOOL)hasVMSReadReceipt;
- (NSDictionary<NSString*, NSDate*>*)vmsReadReceipts;

@end
