//
//  XMPPGroup.h
//  VMSCoreSDK
//
//  Created by Francesco Cosentino on 15/10/2019.
//

#import <XMPPFramework/XMPPFramework.h>

NS_ASSUME_NONNULL_BEGIN

@class XMPPIDTracker;
@protocol XMPPRoomStorage;
@protocol XMPPGroupDelegate;
@class XMPPvCardTemp;

@interface XMPPGroup : XMPPModule
{
/*    Inherited from XMPPModule:
    
    XMPPStream *xmppStream;
 
    dispatch_queue_t moduleQueue;
    id multicastDelegate;
 */
 
     __strong id <XMPPRoomStorage> xmppRoomStorage;
     
    __strong XMPPJID *roomJID;
    
    __strong XMPPJID * _Nullable myRoomJID;
    __strong NSString * _Nullable myNickname;
    __strong NSString * _Nullable myOldNickname;
    
    __strong NSString * _Nullable roomSubject;
    
    XMPPIDTracker * _Nullable responseTracker;
    
    uint16_t state;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype)initWithDispatchQueue:(nullable dispatch_queue_t)queue NS_UNAVAILABLE;
- (instancetype)initWithRoomStorage:(id <XMPPRoomStorage>)storage jid:(XMPPJID *)roomJID;
- (instancetype)initWithRoomStorage:(id <XMPPRoomStorage>)storage jid:(XMPPJID *)roomJID dispatchQueue:(nullable dispatch_queue_t)queue;

/* Inherited from XMPPModule:

- (BOOL)activate:(XMPPStream *)xmppStream;
- (void)deactivate;

@property (readonly) XMPPStream *xmppStream;

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate;

- (NSString *)moduleName;
 
*/

#pragma mark Properties

@property (nonatomic, readonly) id <XMPPRoomStorage> xmppRoomStorage;

@property (nonatomic, readonly) XMPPJID * roomJID;     // E.g. xmpp-development@conference.deusty.com

@property (atomic, readonly, nullable) XMPPJID * myRoomJID;   // E.g. xmpp-development@conference.deusty.com/robbiehanson
@property (atomic, readonly, nullable) NSString * myNickname; // E.g. robbiehanson

@property (atomic, readonly, nullable) NSString *roomSubject;

@property (atomic, readonly) BOOL isJoined;

#pragma mark Room Lifecycle

- (void)useNickname:(NSString *)nickname;

/**
 * Sends a presence element to the join room.
 *
 * If the room already exists, then the xmppRoomDidJoin: delegate method will be invoked upon
 * notifiaction from the server that we successfully joined the room.
 *
 * If the room did not already exist, and the authenticated user is allowed to create the room,
 * then the server will automatically create the room,
 * and the xmppRoomDidCreate: delegate method will be invoked (followed by xmppRoomDidJoin:).
 * You'll then need to configure the room before others can join.
 *
 * @param desiredNickname (required)
 *        The nickname to use within the room.
 *        If the room is anonymous, this is the only identifier other occupants of the room will see.
 *
 * @param history (optional)
 *        A history element specifying how much discussion history to request from the server.
 *        E.g. <history maxstanzas='100'/>
 *        For more information, please see XEP-0045, Section 7.1.16 - Managing Discussion History.
 *        You may also want to query your storage module to see how old the most recent stored message for this room is.
 *
 * @see fetchConfigurationForm
 * @see configureRoomUsingOptions:
**/
- (void)joinRoomUsingNickname:(NSString *)desiredNickname history:(nullable NSXMLElement *)history;
- (void)joinRoomUsingNickname:(NSString *)desiredNickname history:(nullable NSXMLElement *)history password:(nullable NSString *)passwd;

/**
 * There are two ways to configure a room.
 * 1.) Accept the default configuration
 * 2.) Send a custom configuration
 *
 * To see which configuration options the server supports,
 * or to inspect the default options, you'll need to fetch the configuration form.
 *
 * @see configureRoomUsingOptions:
**/
- (void)fetchConfigurationForm;

/**
 * Pass nil to accept the default configuration.
**/
- (void)configureRoomUsingOptions:(nullable NSXMLElement *)roomConfigForm;

- (void)leaveRoom;
- (void)destroyRoom;

#pragma mark Room Interaction

- (void)changeNickname:(NSString *)newNickname;
- (void)changeRoomSubject:(NSString *)newRoomSubject;

- (void)inviteUser:(XMPPJID *)jid withMessage:(nullable NSString *)inviteMessageStr;

- (void)sendMessage:(XMPPMessage *)message;

- (void)sendMessageWithBody:(NSString *)messageBody;

#pragma mark Room Moderation

- (void)fetchBanList;
- (void)fetchMembersList;
- (void)fetchModeratorsList;
- (void)fetchOwner;
- (void)fetchParticipantsList;

- (void)fetchInfo;

/**
 * The ban list, member list, and moderator list are simply subsets of the room privileges list.
 * That is, a user's status as 'banned', 'member', 'moderator', etc,
 * are simply different priveleges that may be assigned to a user.
 *
 * You may edit the list of privileges using this method.
 * The array of items corresponds with the <item/> stanzas of Section 9 of XEP-0045.
 * This class provides helper methods to create these item elements.
 *
 * @see itemWithAffiliation:jid:
 * @see itemWithRole:jid:
 *
 * The authenticated user must be an admin or owner of the room, or the server will deny the request.
 *
 * To add a member: <item
 *
 *
 * @return The id of the XMPPIQ that was sent.
 *         This may be used to match multiple change requests with the responses in xmppRoom:didEditPrivileges:.
**/
- (NSString *)editRoomPrivileges:(NSArray<NSXMLElement*> *)items;

+ (NSXMLElement *)itemWithAffiliation:(nullable NSString *)affiliation jid:(nullable XMPPJID *)jid;
+ (NSXMLElement *)itemWithRole:(nullable NSString *)role jid:(nullable XMPPJID *)jid;

@end

#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol XMPPGroupDelegate
@optional

- (void)xmppRoomDidCreate:(XMPPRoom *)sender;

/**
 * Invoked with the results of a request to fetch the configuration form.
 * The given config form will look something like:
 *
 * <x xmlns='jabber:x:data' type='form'>
 *   <title>Configuration for MUC Room</title>
 *   <field type='hidden'
 *           var='FORM_TYPE'>
 *     <value>http://jabber.org/protocol/muc#roomconfig</value>
 *   </field>
 *   <field label='Natural-Language Room Name'
 *           type='text-single'
 *            var='muc#roomconfig_roomname'/>
 *   <field label='Enable Public Logging?'
 *           type='boolean'
 *            var='muc#roomconfig_enablelogging'>
 *     <value>0</value>
 *   </field>
 *   ...
 * </x>
 *
 * The form is to be filled out and then submitted via the configureRoomUsingOptions: method.
 *
 * @see fetchConfigurationForm:
 * @see configureRoomUsingOptions:
**/
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm;

- (void)xmppRoom:(XMPPRoom *)sender willSendConfiguration:(XMPPIQ *)roomConfigForm;

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult;
- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult;

- (void)xmppRoomDidJoin:(XMPPRoom *)sender affiliation:(NSString*)affiliation role:(NSString*)role;
- (void)xmppRoomDidLeave:(XMPPRoom *)sender;
- (void)xmppRoomDidFailToLeave:(XMPPRoom *)sender;

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender;

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID isAdmin:(BOOL)isAdmin friendlyNick:(NSString*)friendlyNick;
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID isAdmin:(BOOL)isAdmin friendlyNick:(NSString*)friendlyNick;
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID isAdmin:(BOOL)isAdmin friendlyNick:(NSString*)friendlyNick;

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room, or from a non-occupant.
**/
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID;

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError;

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError;

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError;

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult;
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError;

- (void)xmppRoom:(XMPPRoom *)sender didFetchOwner:(NSString *)owner;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchOwner:(XMPPIQ *)iqResult;

- (void)xmppRoom:(XMPPRoom *)sender didFetchParticipantsList:(NSArray *)items;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchParticipants:(XMPPIQ *)iqResult;

- (void)xmppRoom:(XMPPRoom *)sender didFetchInfo:(NSXMLElement *)info;
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchInfo:(NSXMLElement *)info;

- (void)xmppRoom:(XMPPRoom *)sender didReceiveRoomSubject:(NSString*)subject fromOccupant:(XMPPJID *)occupantJID;
- (void)xmppRoomDidSetAvatar:(XMPPRoom *)sender;
- (void)xmppRoom:(XMPPRoom *)sender didReceivevCardTemp:(XMPPvCardTemp*)vCardTemp;
- (void)xmppRoom:(XMPPRoom *)sender didReceiveConfigurationChangeWithCode:(int)code;

- (void)xmppRoomDidBecomeOwner:(XMPPRoom *)sender;
- (void)xmppRoom:(XMPPRoom *)sender occupantDidBecomeOwner:(XMPPJID *)occupantJID;

@end

NS_ASSUME_NONNULL_END
