/**
 * Meanwhile Protocol Plugin for Messages
 * Adds Lotus Sametime support to Purple using the Apple Messages
 *
 * Copyright (C) 2012 Chris Parker <mrcsparker@gmail.com>
 *
 * SametimeServicePlugin is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SametimeServicePlugin is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with SametimeServicePlugin.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import <IMServicePlugIn/IMServicePlugIn.h>

#import <glib.h>

#include <mw_cipher.h>
#include <mw_common.h>
//#include <mw_error.h>
#include <mw_service.h>
#include <mw_session.h>
#include <mw_srvc_aware.h>
#include <mw_srvc_conf.h>
#include <mw_srvc_ft.h>
#include <mw_srvc_im.h>
#include <mw_srvc_place.h>
#include <mw_srvc_resolve.h>
#include <mw_srvc_store.h>
#include <mw_st_list.h>

struct MeanwhileClient
{
    /** The actual meanwhile session */
    struct mwSession *session;
    
    /** Session handler */
    struct mwSessionHandler sessionHandler;
    
    /** Aware service */
    struct mwServiceAware *serviceAware;
    
    /** Aware handler */
    struct mwAwareHandler awareHandler;
    
    /** Aware List Handler */
    struct mwAwareListHandler awareListHandler;
    
    /** The aware list */
    struct mwAwareList *awareList;
    
    /** Aware service */
    struct mwServiceIm *serviceIm;
    
    /** Aware handler */
    struct mwImHandler imHandler;
    
    /** Resolve service */
    struct mwServiceResolve *serviceResolve;
    
    /** Storage service, for contact list */
    struct mwServiceStorage *serviceStorage;
    
    /** The socket connecting to the server */
    int sock;
    
    /* glib event id polling the socket */
    int sockEvent;
    
    void *application;
    
};

@interface SametimeServicePlugin : NSObject <
    IMServicePlugIn,
    IMServicePlugInChatRoomSupport,
    IMServicePlugInGroupListSupport,
    IMServicePlugInInstantMessagingSupport,
    IMServicePlugInPresenceSupport>
{
    
    struct MeanwhileClient *client;
}

@property (assign) id <
    IMServiceApplication,
    IMServiceApplicationChatRoomSupport,
    IMServiceApplicationGroupListSupport,
    IMServiceApplicationInstantMessagingSupport> application;
@property (retain) NSDictionary *accountSettings;

@end
