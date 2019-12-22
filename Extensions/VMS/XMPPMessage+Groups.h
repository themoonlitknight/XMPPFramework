//
//  XMPPMessage+Groups.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 15/10/2019.
//

#import <XMPPFramework/XMPPFramework.h>

NS_ASSUME_NONNULL_BEGIN

@interface XMPPMessage (Groups)

- (int)configurationChangeForGroupChatMessage;

@end

NS_ASSUME_NONNULL_END
