//
//  XMPPPresence+RoomOccupant.h
//  VMS
//
//  Created by Francesco Cosentino on 19/03/15.
//
//

#import "XMPPPresence.h"

@interface XMPPPresence (RoomOccupant)

- (NSString*)vms_occupantFullJIDString;
- (BOOL)vms_occupantIsOwner;

//TEMP
- (NSString*)RO_fullJIDString;
- (BOOL)RO_isOwner;

@end
