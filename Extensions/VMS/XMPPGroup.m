//
//  XMPPGroup.m
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 15/10/2019.
//

#import "XMPPGroup.h"
#import "XMPPMessage+Groups.h"

enum XMPPRoomState
{
    kXMPPRoomStateNone        = 0,
    kXMPPRoomStateCreated     = 1 << 1,
    kXMPPRoomStateJoining     = 1 << 3,
    kXMPPRoomStateJoined      = 1 << 4,
    kXMPPRoomStateLeaving     = 1 << 5,
};

@implementation XMPPGroup

- (instancetype) init
{
    // This will cause a crash - it's designed to.
    // Only the init methods listed in XMPPRoom.h are supported.
    
    return [self initWithRoomStorage:nil jid:nil dispatchQueue:NULL];
}

- (instancetype)initWithDispatchQueue:(nullable dispatch_queue_t)queue
{
    // This will cause a crash - it's designed to.
    // Only the init methods listed in XMPPRoom.h are supported.
    
    return [self initWithRoomStorage:nil jid:nil dispatchQueue:queue];
}

- (instancetype)initWithRoomStorage:(id <XMPPRoomStorage>)storage jid:(XMPPJID *)aRoomJID
{
    return [self initWithRoomStorage:storage jid:aRoomJID dispatchQueue:NULL];
}

- (instancetype)initWithRoomStorage:(id <XMPPRoomStorage>)storage jid:(XMPPJID *)aRoomJID dispatchQueue:(dispatch_queue_t)queue
{
    NSParameterAssert(storage != nil);
    NSParameterAssert(aRoomJID != nil);
    
    if ((self = [super initWithDispatchQueue:queue]))
    {
        if ([storage configureWithParent:self queue:moduleQueue])
        {
            xmppRoomStorage = storage;
        }
        else
        {
            
        }
        
        roomJID = [aRoomJID bareJID];
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    if ([super activate:aXmppStream])
    {
        responseTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
        
        return YES;
    }
    
    return NO;
}

- (void)deactivate
{
    dispatch_block_t block = ^{ @autoreleasepool {

//        if (self.isJoined)
//        {
//            [self leaveRoom];
//        }
        
        [responseTracker removeAllIDs];
        responseTracker = nil;
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    [super deactivate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Internal
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method may optionally be used by XMPPRosterStorage classes (method declared in XMPPRosterPrivate.h)
**/
- (dispatch_queue_t)moduleQueue
{
    return moduleQueue;
}

/**
 * This method may optionally be used by XMPPRosterStorage classes (method declared in XMPPRosterPrivate.h).
**/
- (GCDMulticastDelegate *)multicastDelegate
{
    return multicastDelegate;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id <XMPPRoomStorage>)xmppRoomStorage
{
    // This variable is readonly - set in init method and never changed.
    return xmppRoomStorage;
}

- (XMPPJID *)roomJID
{
    // This variable is readonly - set in init method and never changed.
    return roomJID;
}

- (XMPPJID *)myRoomJID
{
    if (dispatch_get_specific(moduleQueueTag))
    {
        return myRoomJID;
    }
    else
    {
        __block XMPPJID *result;
        
        dispatch_sync(moduleQueue, ^{
            result = myRoomJID;
        });
        
        return result;
    }
}

- (NSString *)myNickname
{
    if (dispatch_get_specific(moduleQueueTag))
    {
        return myNickname;
    }
    else
    {
        __block NSString *result;
        
        dispatch_sync(moduleQueue, ^{
            result = myNickname;
        });
        
        return result;
    }
}

- (NSString *)roomSubject
{
    if (dispatch_get_specific(moduleQueueTag))
    {
        return roomSubject;
    }
    else
    {
        __block NSString *result;
        
        dispatch_sync(moduleQueue, ^{
            result = roomSubject;
        });
        
        return result;
    }
}

- (BOOL)isJoined
{
    __block BOOL result = 0;
    
    dispatch_block_t block = ^{
        result = (state & kXMPPRoomStateJoined) ? YES : NO;
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return result;
}
/*
- (BOOL)isRoomOwner
{
    __block BOOL result;
    
    dispatch_block_t block = ^{
        
        id <XMPPRoomOccupant> myOccupant = [xmppRoomStorage occupantForJID:myRoomJID stream:xmppStream];
        
        result = [myOccupant.affiliation isEqualToString:@"owner"];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return result;
}
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Create & Join
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//- (void)setJoinedStateWithNickname:(NSString *)nickname
//{
//    myNickname = [nickname copy];
//    myRoomJID = [XMPPJID jidWithUser:[roomJID user] domain:[roomJID domain] resource:myNickname];
//
//    state &= ~kXMPPRoomStateCreated;
//    state &= ~kXMPPRoomStateJoining;
//    state &= ~kXMPPRoomStateLeaving;
//    state |= kXMPPRoomStateJoined;
//}

- (void)useNickname:(NSString *)nickname
{
    myNickname = [nickname copy];
    myRoomJID = [XMPPJID jidWithUser:[roomJID user] domain:[roomJID domain] resource:myNickname];
}

- (BOOL)preJoinWithNickname:(NSString *)nickname
{
    if ((state != kXMPPRoomStateNone) && (state != kXMPPRoomStateLeaving))
    {
        return NO;
    }
    
    myNickname = [nickname copy];
    myRoomJID = [XMPPJID jidWithUser:[roomJID user] domain:[roomJID domain] resource:myNickname];
    
    return YES;
}

- (void)joinRoomUsingNickname:(NSString *)desiredNickname history:(nullable NSXMLElement *)history;
{
    [self joinRoomUsingNickname:desiredNickname history:history password:nil];
}

- (void)joinRoomUsingNickname:(NSString *)desiredNickname history:(nullable NSXMLElement *)history password:(nullable NSString *)passwd;
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // Check state and update variables
        
        if (![self preJoinWithNickname:desiredNickname])
        {
            return;
        }
        
        // <presence to='darkcave@chat.shakespeare.lit/firstwitch'>
        //   <x xmlns='http://jabber.org/protocol/muc'/>
        //     <history/>
        //     <password>passwd</password>
        //   </x>
        // </presence>
        
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCNamespace];
        if (history)
        {
            [x addChild:history];
        }
        if (passwd)
        {
            [x addChild:[NSXMLElement elementWithName:@"password" stringValue:passwd]];
        }
        
        XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:myRoomJID];
        [presence addChild:x];
        
        [xmppStream sendElement:presence];
        
        state |= kXMPPRoomStateJoining;
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Room Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)handleConfigurationFormResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        // <iq type='result'
        //     from='coven@chat.shakespeare.lit'
        //       id='create1'>
        //   <query xmlns='http://jabber.org/protocol/muc#owner'>
        //     <x xmlns='jabber:x:data' type='form'>
        //       <title>Configuration for "coven" Room</title>
        //       <field type='hidden'
        //               var='FORM_TYPE'>
        //         <value>http://jabber.org/protocol/muc#roomconfig</value>
        //       </field>
        //       <field label='Natural-Language Room Name'
        //               type='text-single'
        //                var='muc#roomconfig_roomname'/>
        //       <field label='Enable Public Logging?'
        //               type='boolean'
        //                var='muc#roomconfig_enablelogging'>
        //         <value>0</value>
        //       </field>
        //       ...
        //     </x>
        //   </query>
        // </iq>
        
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPMUCOwnerNamespace];
        NSXMLElement *x = [query elementForName:@"x" xmlns:@"jabber:x:data"];
        
        [multicastDelegate xmppRoom:self didFetchConfigurationForm:x];
    }
}

- (void)fetchConfigurationForm
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type='get'
        //       id='config1'
        //       to='coven@chat.shakespeare.lit'>
        //   <query xmlns='http://jabber.org/protocol/muc#owner'/>
        // </iq>
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                        target:self
                      selector:@selector(handleConfigurationFormResponse:withInfo:)
                       timeout:60.0];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleConfigureRoomResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        [multicastDelegate xmppRoom:self didConfigure:iq];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotConfigure:iq];
    }
}

- (void)configureRoomUsingOptions:(nullable NSXMLElement *)roomConfigForm;
{
    dispatch_block_t block = ^{ @autoreleasepool {
 
        if (roomConfigForm)
        {
            // Explicit configuration using given form.
            //
            // <iq type='set'
            //       id='create2'
            //       to='coven@chat.shakespeare.lit'>
            //   <query xmlns='http://jabber.org/protocol/muc#owner'>
            //     <x xmlns='jabber:x:data' type='submit'>
            //       <field var='FORM_TYPE'>
            //         <value>http://jabber.org/protocol/muc#roomconfig</value>
            //       </field>
            //       <field var='muc#roomconfig_roomname'>
            //         <value>A Dark Cave</value>
            //       </field>
            //       <field var='muc#roomconfig_enablelogging'>
            //         <value>0</value>
            //       </field>
            //       ...
            //     </x>
            //   </query>
            // </iq>
            
            NSXMLElement *x = roomConfigForm;
            [x addAttributeWithName:@"type" stringValue:@"submit"];
            
            NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
            [query addChild:x];
            
            NSString *iqID = [xmppStream generateUUID];
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:roomJID elementID:iqID child:query];
            
            [xmppStream sendElement:iq];
            
            [responseTracker addID:iqID
                            target:self
                          selector:@selector(handleConfigureRoomResponse:withInfo:)
                           timeout:60.0];
        }
        else
        {
            // Default room configuration (as per server settings).
            //
            // <iq type='set'
            //     from='crone1@shakespeare.lit/desktop'
            //       id='create1'
            //       to='darkcave@chat.shakespeare.lit'>
            //   <query xmlns='http://jabber.org/protocol/muc#owner'>
            //     <x xmlns='jabber:x:data' type='submit'/>
            //   </query>
            // </iq>
            
            NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            [x addAttributeWithName:@"type" stringValue:@"submit"];
            
            NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
            [query addChild:x];
            
            NSString *iqID = [xmppStream generateUUID];
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:roomJID elementID:iqID child:query];
            
            [xmppStream sendElement:iq];
            
            [responseTracker addID:iqID
                            target:self
                          selector:@selector(handleConfigureRoomResponse:withInfo:)
                           timeout:60.0];
        }
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)changeNickname:(NSString *)newNickname
{
    myOldNickname = [myNickname copy];
    myNickname = [newNickname copy];
    myRoomJID = [XMPPJID jidWithUser:[roomJID user] domain:[roomJID domain] resource:myNickname];
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:myRoomJID];
    [xmppStream sendElement:presence];
}

- (void)changeRoomSubject:(NSString *)newRoomSubject
{
    // Todo
}

- (void)handleFetchBanListResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        // <iq type='result'
        //     from='southampton@henryv.shakespeare.lit'
        //       id='ban2'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item affiliation='outcast' jid='earlofcambridge@shakespeare.lit'>
        //       <reason>Treason</reason>
        //     </item>
        //   </query>
        // </iq>
        
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPMUCAdminNamespace];
        NSArray *items = [query elementsForName:@"item"];
        
        [multicastDelegate xmppRoom:self didFetchBanList:items];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchBanList:iq];
    }
}

- (void)fetchBanList
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type='get'
        //       id='ban2'
        //       to='southampton@henryv.shakespeare.lit'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item affiliation='outcast'/>
        //   </query>
        // </iq>
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"affiliation" stringValue:@"outcast"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                       target:self
                     selector:@selector(handleFetchBanListResponse:withInfo:)
                      timeout:60.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleFetchMembersListResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        // <iq type='result'
        //     from='coven@chat.shakespeare.lit'
        //       id='member3'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item affiliation='member' jid='hag66@shakespeare.lit' nick='thirdwitch' role='participant'/>
        //   </query>
        // </iq>
        
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPMUCAdminNamespace];
        NSArray *items = [query elementsForName:@"item"];
        
        [multicastDelegate xmppRoom:self didFetchMembersList:items];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchMembersList:iq];
    }
}

- (void)fetchMembersList
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type='get'
        //       id='member3'
        //       to='coven@chat.shakespeare.lit'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item affiliation='member'/>
        //   </query>
        // </iq>
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"affiliation" stringValue:@"member"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                       target:self
                     selector:@selector(handleFetchMembersListResponse:withInfo:)
                      timeout:60.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
    
    
}

- (void)handleFetchModeratorsListResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        // <iq type='result'
        //       id='mod3'
        //       to='crone1@shakespeare.lit/desktop'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item affiliation='member' jid='hag66@shakespeare.lit/pda' nick='thirdwitch' role='moderator'/>
        //   </query>
        // </iq>
        
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPMUCAdminNamespace];
        NSArray *items = [query elementsForName:@"item"];
        
        [multicastDelegate xmppRoom:self didFetchModeratorsList:items];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchModeratorsList:iq];
    }
}

- (void)fetchModeratorsList
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type='get'
        //       id='mod3'
        //       to='coven@chat.shakespeare.lit'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item role='moderator'/>
        //   </query>
        // </iq>
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"role" stringValue:@"moderator"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                       target:self
                     selector:@selector(handleFetchModeratorsListResponse:withInfo:)
                      timeout:60.0];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleFetchOwnerResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPMUCAdminNamespace];
        NSString *jid = [[query elementForName:@"item"] attributeStringValueForName:@"jid"];
        
        [multicastDelegate xmppRoom:self didFetchOwner:jid];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchOwner:iq];
    }
}

- (void)fetchOwner
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
        [item addAttributeWithName:@"affiliation" stringValue:@"owner"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
        [query addChild:item];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                        target:self
                      selector:@selector(handleFetchOwnerResponse:withInfo:)
                       timeout:60.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleFetchParticipantsListResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPDiscoItemsNamespace];
        NSArray *items = [query elementsForName:@"item"];
        
        [multicastDelegate xmppRoom:self didFetchParticipantsList:items];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchParticipants:iq];
    }
}

- (void)fetchParticipantsList
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPDiscoItemsNamespace];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                        target:self
                      selector:@selector(handleFetchParticipantsListResponse:withInfo:)
                       timeout:60.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleFetchInfoResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        NSXMLElement *query = [iq elementForName:@"query" xmlns:XMPPDiscoInfoNamespace];
        
        [multicastDelegate xmppRoom:self didFetchInfo:query];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotFetchInfo:iq];
    }
}

- (void)fetchInfo
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        NSString *fetchID = [xmppStream generateUUID];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPDiscoInfoNamespace];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:fetchID
                        target:self
                      selector:@selector(handleFetchInfoResponse:withInfo:)
                       timeout:60.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleEditRoomPrivilegesResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        [multicastDelegate xmppRoom:self didEditPrivileges:iq];
    }
    else
    {
        [multicastDelegate xmppRoom:self didNotEditPrivileges:iq];
    }
}

- (NSString *)editRoomPrivileges:(NSArray<NSXMLElement*> *)items
{
    NSString *iqID = [xmppStream generateUUID];
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type='set'
        //       id='mod4'
        //       to='coven@chat.shakespeare.lit'>
        //   <query xmlns='http://jabber.org/protocol/muc#admin'>
        //     <item jid='hag66@shakespeare.lit/pda' role='participant'/>
        //     <item jid='hecate@shakespeare.lit/broom' role='moderator'/>
        //   </query>
        // </iq>
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
        for (NSXMLElement *item in items)
        {
            [query addChild:item];
        }
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:roomJID elementID:iqID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:iqID
                        target:self
                      selector:@selector(handleEditRoomPrivilegesResponse:withInfo:)
                       timeout:60.0];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
    
    return iqID;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Leave & Destroy
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)handleLeaveRoomResponse:(XMPPElement *)element withInfo:(id <XMPPTrackingInfo>)info
{
    if (element) {
        [xmppRoomStorage handleDidLeaveRoom:self];
        [multicastDelegate xmppRoomDidLeave:self];
    }
    else {
        // error
        [multicastDelegate xmppRoomDidFailToLeave:self];
    }
}

- (void)leaveRoom
{
    dispatch_block_t block = ^{ @autoreleasepool {
               
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable" to:myRoomJID];
        
        NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"comment"];
        [presence addChild:status];
        
        [xmppStream sendElement:presence];
        
        state &= ~kXMPPRoomStateJoining;
        state &= ~kXMPPRoomStateJoined;
        state |=  kXMPPRoomStateLeaving;
        
        [responseTracker addID:@"leave"
                        target:self
                      selector:@selector(handleLeaveRoomResponse:withInfo:)
                       timeout:30.0];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)handleDestroyRoomResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    if ([[iq type] isEqualToString:@"result"])
    {
        [multicastDelegate xmppRoomDidDestroy:self];
    }
    else
    {
        // Todo...
    }
}

- (void)destroyRoom
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <iq type="set" to="roomName" id="abc123">
        //   <query xmlns="http://jabber.org/protocol/muc#owner">
        //     <destroy/>
        //   </query>
        // </iq>
        
        NSXMLElement *destroy = [NSXMLElement elementWithName:@"destroy"];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCOwnerNamespace];
        [query addChild:destroy];
        
        NSString *iqID = [xmppStream generateUUID];
        
        XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:roomJID elementID:iqID child:query];
        
        [xmppStream sendElement:iq];
        
        [responseTracker addID:iqID
                            target:self
                          selector:@selector(handleDestroyRoomResponse:withInfo:)
                           timeout:60.0];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Messages
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)inviteUser:(XMPPJID *)jid withMessage:(nullable NSString *)inviteMessageStr;
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        // <message to='darkcave@chat.shakespeare.lit'>
        //   <x xmlns='http://jabber.org/protocol/muc#user'>
        //     <invite to='hecate@shakespeare.lit'>
        //       <reason>
        //         Hey Hecate, this is the place for all good witches!
        //       </reason>
        //     </invite>
        //   </x>
        // </message>
        
        NSXMLElement *invite = [NSXMLElement elementWithName:@"invite"];
        [invite addAttributeWithName:@"to" stringValue:[jid full]];
        
        if ([inviteMessageStr length] > 0)
        {
            [invite addChild:[NSXMLElement elementWithName:@"reason" stringValue:inviteMessageStr]];
        }
        
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCUserNamespace];
        [x addChild:invite];
        
        XMPPMessage *message = [XMPPMessage message];
        [message addAttributeWithName:@"to" stringValue:[roomJID full]];
        [message addChild:x];
        
        [xmppStream sendElement:message];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)sendMessage:(XMPPMessage *)message
{
    dispatch_block_t block = ^{ @autoreleasepool {
        
        [message addAttributeWithName:@"to" stringValue:[roomJID full]];
        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
        
        [xmppStream sendElement:message];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)sendMessageWithBody:(NSString *)messageBody
{
    if ([messageBody length] == 0) return;
        
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:messageBody];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addChild:body];
    
    [self sendMessage:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    // This method is invoked on the moduleQueue.
    
    state = kXMPPRoomStateNone;
    
    // Auto-rejoin?
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSString *type = [iq type];
    
    if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"])
    {
        // avatar?
        if ([type isEqualToString:@"result"]) {
            XMPPJID *from = [iq from];
            
            if (![roomJID isEqualToJID:from options:XMPPJIDCompareBare])
            {
                return NO; // Stanza isn't for our room
            }
            
            NSXMLElement *vCardTemp;
            if ((vCardTemp = [iq elementForName:@"vCard" xmlns:@"vcard-temp"])) {
                // is vCardTemp
                if (vCardTemp.childCount > 0) {
                    // vCardTemp received
                    [multicastDelegate xmppRoom:self didReceivevCardTemp:[XMPPvCardTemp vCardTempFromElement:vCardTemp]];
                }
                else {
                    // avatar has been successfully uploaded
                    [multicastDelegate xmppRoomDidSetAvatar:self];
                }
                return YES;
            }
        }
        
        return [responseTracker invokeForID:[iq elementID] withObject:iq];
    }
    
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    // This method is invoked on the moduleQueue.
    
    XMPPJID *from = [presence from];
    
    if (![roomJID isEqualToJID:from options:XMPPJIDCompareBare])
    {
        return; // Stanza isn't for our room
    }
    
    [xmppRoomStorage handlePresence:presence room:self];
    
    // My presence:
    //
    // <presence from='coven@chat.shakespeare.lit/thirdwitch'>
    //   <x xmlns='http://jabber.org/protocol/muc#user'>
    //     <item affiliation='member' role='participant'/>
    //     <status code='110'/>
    //     <status code='210'/>
    //   </x>
    // </presence>
    //
    //
    // Another's presence:
    //
    // <presence from='coven@chat.shakespeare.lit/firstwitch'>
    //   <x xmlns='http://jabber.org/protocol/muc#user'>
    //     <item affiliation='owner' role='moderator'/>
    //   </x>
    // </presence>
    
    NSXMLElement *x = [presence elementForName:@"x" xmlns:XMPPMUCUserNamespace];
    
    // Process status codes.
    //
    // 110 - Inform user that presence refers to one of its own room occupants.
    // 201 - Inform user that a new room has been created.
    // 210 - Inform user that service has assigned or modified occupant's roomnick.
    // 303 - Inform all occupants of new room nickname.
    
    BOOL isMyPresence = NO;
    BOOL didCreateRoom = NO;
    BOOL isNicknameChange = NO;
    
    for (NSXMLElement *status in [x elementsForName:@"status"])
    {
        switch ([status attributeIntValueForName:@"code"])
        {
            case 110 : isMyPresence = YES;     break;
            case 201 : didCreateRoom = YES;    break;
            case 210 :
            case 303 : isNicknameChange = YES; break;
        }
    }
    
    // Extract presence type
    
    NSString *presenceType = [presence type];
    
    BOOL isAvailable   = [presenceType isEqualToString:@"available"];
    BOOL isLeaving = NO;
    if ([presenceType isEqualToString:@"unavailable"]) {
        if (isMyPresence) {
            NSXMLElement *status = [presence elementForName:@"status"];
            if ([[status stringValue] isEqualToString:@"leave"]) {
                isLeaving = YES;
            }
        }
//        else {
//            NSXMLElement *item = [x elementForName:@"item"];
//            if ([[item attributeStringValueForName:@"role"] isEqualToString:@"none"]) {
//                isLeaving = YES;
//            }
//        }
    }
    
    // Server's don't always properly send the statusCodes in every situation.
    // So we have some extra checks to ensure the boolean variables are correct.
    
    if (didCreateRoom)
    {
        isMyPresence = YES;
    }
    if (!isMyPresence)
    {
        if ([[from resource] isEqualToString:myNickname])
            isMyPresence = YES;
    }
    if (!isMyPresence && isNicknameChange && myOldNickname)
    {
        if ([[from resource] isEqualToString:myOldNickname]) {
            isMyPresence = YES;
            myOldNickname = nil;
        }
    }
    
    // Process presence
    
    if (didCreateRoom)
    {
        state |= kXMPPRoomStateCreated;
        
        [multicastDelegate xmppRoomDidCreate:self];
    }
    
    if (isMyPresence)
    {
        if (isAvailable)
        {
            myRoomJID = from;
            myNickname = [from resource];
            
            if (state & kXMPPRoomStateJoining)
            {
                state &= ~kXMPPRoomStateJoining;
                state |=  kXMPPRoomStateJoined;
                
                NSXMLElement *item = [x elementForName:@"item"];
                NSString *affiliation = [item attributeStringValueForName:@"affiliation"];
                NSString *role = [item attributeStringValueForName:@"role"];
                
                if ([xmppRoomStorage respondsToSelector:@selector(handleDidJoinRoom:withNickname:)])
                    [xmppRoomStorage handleDidJoinRoom:self withNickname:myNickname];
                [multicastDelegate xmppRoomDidJoin:self affiliation:affiliation role:role];
            }
        }
        else if (isLeaving && !isNicknameChange)
        {
            state = kXMPPRoomStateNone;
        }
    }
    else
    {
        NSXMLElement *item = [x elementForName:@"item"];
        if (item == nil) {
            return;
        }
        
        BOOL isAdmin = [[item attributeStringValueForName:@"affiliation"] isEqualToString:@"owner"];
        NSString *friendlyNick = [item attributeStringValueForName:@"name"];
        
        if (isAvailable) {
            [multicastDelegate xmppRoom:self occupantDidJoin:from isAdmin:isAdmin friendlyNick:friendlyNick];
        }
        else if (isLeaving) {
            [multicastDelegate xmppRoom:self occupantDidLeave:from isAdmin:isAdmin friendlyNick:friendlyNick];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    // This method is invoked on the moduleQueue.
    
    XMPPJID *from = [message from];
    
    if (![roomJID isEqualToJID:from options:XMPPJIDCompareBare])
    {
        return; // Stanza isn't for our room
    }
    
    // Is this a message we need to store (a chat message)?
    //
    // A message to all recipients MUST be of type groupchat.
    // A message to an individual recipient would have a <body/>.
    
    BOOL isChatMessage;
    int code;
    
    if ([from isFull])
        isChatMessage = [message isGroupChatMessageWithBody];
    else
        isChatMessage = [message isMessageWithBody];
    
    if (isChatMessage)
    {
        [xmppRoomStorage handleIncomingMessage:message room:self];
        [multicastDelegate xmppRoom:self didReceiveMessage:message fromOccupant:from];
    }
    else if ([message isGroupChatMessageWithSubject])
    {
        roomSubject = [message subject];
        
        [multicastDelegate xmppRoom:self didReceiveRoomSubject:roomSubject fromOccupant:from];
    }
    else if ((code = [message configurationChangeForGroupChatMessage]) >= 0) {
        if (code >= 0) {
            [multicastDelegate xmppRoom:self didReceiveConfigurationChangeWithCode:code];
        }
    }
    else if (message.type == nil || [message.type isEqualToString:@"normal"]) {
        // change of affiliation
        NSXMLElement *item = [[message elementForName:@"x" xmlns:XMPPMUCUserNamespace] elementForName:@"item"];
        if (item) {
            NSString *affiliation = [item attributeStringValueForName:@"affiliation"];
            if ([affiliation isEqualToString:@"member"]) {
                /*
                <message from="group4@conference.x.dev.vms.me" type="normal" to="psi1@x.dev.vms.me" id="15798104925061852720">
                  <x xmlns="http://jabber.org/protocol/muc#user">
                    <item affiliation="member" jid="psi2@x.dev.vms.me"/>
                    <store xmlns="urn:xmpp:hints"/>
                    <no-permanent-store xmlns="urn:xmpp:hints"/>
                  </x>
                </message>
                 */
                
                // joining
                NSString *nickname = [[XMPPJID jidWithString:[item attributeStringValueForName:@"jid"]] user];
                XMPPJID *occupantJID = [XMPPJID jidWithString:message.fromStr resource:nickname];
                BOOL isAdmin = [[item attributeStringValueForName:@"affiliation"] isEqualToString:@"owner"];
                NSString *friendlyNick = [item attributeStringValueForName:@"name"];
                [multicastDelegate xmppRoom:self occupantDidJoin:occupantJID isAdmin:isAdmin friendlyNick:friendlyNick];
            }
            else if ([affiliation isEqualToString:@"none"]) {
                /*
                <message from="group4@conference.x.dev.vms.me" type="normal" to="psi1@x.dev.vms.me" id="15798104925061852720">
                  <x xmlns="http://jabber.org/protocol/muc#user">
                    <item affiliation="none" jid="psi2@x.dev.vms.me"/>
                    <store xmlns="urn:xmpp:hints"/>
                    <no-permanent-store xmlns="urn:xmpp:hints"/>
                  </x>
                </message>
                 */
                
                // leaving
                NSString *nickname = [[XMPPJID jidWithString:[item attributeStringValueForName:@"jid"]] user];
                BOOL isMe = [nickname isEqualToString:self.xmppStream.myJID.user];
                XMPPJID *occupantJID = [XMPPJID jidWithString:message.fromStr resource:nickname];
                BOOL isAdmin = [[item attributeStringValueForName:@"affiliation"] isEqualToString:@"owner"];
                NSString *friendlyNick = [item attributeStringValueForName:@"name"];
                if (isMe) {
                    [responseTracker invokeForID:@"leave" withObject:message];
                }
                else {
                    [multicastDelegate xmppRoom:self occupantDidLeave:occupantJID isAdmin:isAdmin friendlyNick:friendlyNick];
                }
            }
            else if ([affiliation isEqualToString:@"owner"]) {
                // new owner
                NSString *nickname = [[XMPPJID jidWithString:[item attributeStringValueForName:@"jid"]] user];
                if ([nickname isEqualToString:myNickname]) {
                    [multicastDelegate xmppRoomDidBecomeOwner:self];
                }
                else {
                    XMPPJID *occupantJID = [XMPPJID jidWithString:message.fromStr resource:nickname];
                    [multicastDelegate xmppRoom:self occupantDidBecomeOwner:occupantJID];
                }
            }
        }
    }
    else if ([message isErrorMessage]) {
        if ([[message errorMessage] code] == 406) {
            //TODO
        }
    }
    else
    {
        // Todo... Handle other types of messages.
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    // This method is invoked on the moduleQueue.
    
    XMPPJID *to = [message to];
    
    if (![roomJID isEqualToJID:to options:XMPPJIDCompareBare])
    {
        return; // Stanza isn't for our room
    }
    
    // Is this a message we need to store (a chat message)?
    //
    // A message to all recipients MUST be of type groupchat.
    // A message to an individual recipient would have a <body/>.
    
    BOOL isChatMessage;
    
    if ([to isFull])
        isChatMessage = [message isGroupChatMessageWithBody];
    else
        isChatMessage = [message isMessageWithBody];
    
    if (isChatMessage)
    {
        [xmppRoomStorage handleOutgoingMessage:message room:self];
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    // This method is invoked on the moduleQueue.
    
    state = kXMPPRoomStateNone;
    [responseTracker removeAllIDs];
    
//    [xmppRoomStorage handleDidLeaveRoom:self];
//    [multicastDelegate xmppRoomDidLeave:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSXMLElement *)itemWithAffiliation:(nullable NSString *)affiliation jid:(nullable XMPPJID *)jid;
{
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    
    if (affiliation)
        [item addAttributeWithName:@"affiliation" stringValue:affiliation];
    
    if (jid)
        [item addAttributeWithName:@"jid" stringValue:[jid full]];
    
    return item;
}

+ (NSXMLElement *)itemWithRole:(nullable NSString *)role jid:(nullable XMPPJID *)jid;
{
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    
    if (role)
        [item addAttributeWithName:@"role" stringValue:role];
    
    if (jid)
        [item addAttributeWithName:@"jid" stringValue:[jid full]];
    
    return item;
}

@end
