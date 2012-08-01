/**
 *  Meanwhile Protocol Plugin for Messages
 *  Adds Lotus Sametime support to Purple using the Apple Messages
 *
 *  Copyright (C) 2012 Chris Parker <mrcsparker@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111-1301,
 *  USA.
 */

#import <IMServicePlugIn/IMServicePlugIn.h>
#import "SametimeServicePlugin.h"

#import <netdb.h>
#import <netinet/in.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <unistd.h>

// - start C code

static int initiateSocket(const char *host, int port)
{
    struct sockaddr_in serverName;
    int sock;
    struct hostent *hostinfo;
    
    sock = socket(PF_INET, SOCK_STREAM, 0);
    if (socket < 0) {
        exit(1);
    }

    serverName.sin_family = AF_INET;
    serverName.sin_port = htons(port);
    hostinfo = gethostbyname(host);
    if (hostinfo == NULL) {
        exit(1);
    }
    serverName.sin_addr = *(struct in_addr *) hostinfo->h_addr;
    
    connect(sock, (struct sockaddr *)&serverName, sizeof(serverName));
    
    return sock;
}

static int sessionIoWrite(struct mwSession *session, const guchar *buf, gsize len)
{
    struct MeanwhileClient *client;
    long ret = 0;
    
    client = mwSession_getClientData(session);
    
    g_return_val_if_fail(client != NULL, -1);
    
    while(len) {
        ret = write(client->sock, buf, len);
        if (ret <= 0) {
            break;
        }
        len -= ret;
        buf += ret;
    }
    
    if (len > 0) {
        g_source_remove(client->sockEvent);
        
        close(client->sock);
        
        client->sock = 0;
        client->sockEvent = 0;
    
        return -1;
    }
    
    return 0;
}

static void sessionIoClose(struct mwSession *session)
{
    struct MeanwhileClient *client;
    
    client = mwSession_getClientData(session);
    g_return_if_fail(client != NULL);
    
    if (client->sock) {
        g_source_remove(client->sockEvent);
        close(client->sock);
        client->sock = 0;
        client->sockEvent = 0;
    }
}

static void sessionOnStateChange(struct mwSession *session, enum mwSessionState state, gpointer info)
{
    switch (state) {
        case mwSession_STARTING:
        case mwSession_HANDSHAKE:
        case mwSession_HANDSHAKE_ACK:
        case mwSession_LOGIN:
        case mwSession_LOGIN_CONT:
        case mwSession_LOGIN_ACK:
            break;
            
        case mwSession_LOGIN_REDIR:
            break;
            
        case mwSession_STARTED:
        {
            struct mwUserStatus stat = { mwStatus_ACTIVE, 0, 0L };
            mwSession_setUserStatus(session, &stat);
        }
            break;
            
        case mwSession_STOPPING:
            break;
            
        case mwSession_STOPPED:
            break;
            
        case mwSession_UNKNOWN:
            break;
            
        default:
            break;
    }
}

static void sessionOnSetPrivacyInfo(struct mwSession *session)
{
    
}

static void sessionOnSetUserStatus(struct mwSession *session)
{
    //struct mwUserStatus *userStatus = mwSession_getUserStatus(session);
    
}

static void sessionOnAdmin(struct mwSession *session, const char *text)
{
    
}

static void sessionOnAnnounce(struct mwSession *session, struct mwLoginInfo *from, gboolean mayReply, const char *text)
{

}

static void sessionClear(struct mwSession *session)
{
    
}

static void awareOnAttrib(struct mwServiceAware *srvc, struct mwAwareAttribute *attrib)
{
    
}

static void awareClear(struct mwServiceAware *srvc)
{
    
}

static void awareListOnAware(struct mwAwareList *list, struct mwAwareSnapshot *id)
{
}

static void awareListOnAttrib(struct mwAwareList *list, struct mwAwareIdBlock *id, struct mwAwareAttribute *attrib)
{
    
}

static void awareListClear(struct mwAwareList *list)
{
    
}

static void imConversationOpened(struct mwConversation *conv)
{
    struct mwServiceIm *srvc;
    struct mwSession *session;;
    struct MeanwhileClient *client;
    struct mwIdBlock *idb;
    
    /* get a reference to the client data */
    srvc = mwConversation_getService(conv);
    session = mwService_getSession(MW_SERVICE(srvc));
    client = mwSession_getClientData(session);
    idb = mwConversation_getTarget(conv);
    
    
    
}

static void imConversationClosed(struct mwConversation *conv, guint32 err)
{

}

static void imConversationRecv(struct mwConversation *conv, enum mwImSendType type, gconstpointer msg)
{
    struct mwServiceIm *srvc;
    struct mwSession *session;
    struct MeanwhileClient *client;
    struct mwIdBlock *target;
    
    srvc = mwConversation_getService(conv);
    session = mwService_getSession(MW_SERVICE(srvc));
    client = mwSession_getClientData(session);
    target = mwConversation_getTarget(conv);
    
    IMServicePlugInMessage *message = [IMServicePlugInMessage alloc];
    message.content = [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:msg]];
    
    NSString *user = [[NSString alloc] initWithUTF8String:target->user];
    
    switch (type) {
        case mwImSend_PLAIN:
            [ (__bridge id)client->application plugInDidReceiveMessage:message fromHandle:user ];
            break;
        case mwImSend_TYPING:
            [ (__bridge id)client->application handleDidStartTyping:user ];
            break;
        case mwImSend_HTML:
            [ (__bridge id)client->application plugInDidReceiveMessage:message fromHandle:user ];
            break;
        case mwImSend_SUBJECT:
            [ (__bridge id)client->application plugInDidReceiveMessage:message fromHandle:user ];
            break;
        case mwImSend_MIME:
            [ (__bridge id)client->application plugInDidReceiveMessage:message fromHandle:user ];
            break;
        case mwImSend_TIMESTAMP:
            [ (__bridge id)client->application plugInDidReceiveMessage:message fromHandle:user ];
            break;
    }
}

static void imClear(struct mwServiceIm *srvc)
{
    
}

// - end C code

@implementation SametimeServicePlugin

- (void) dealloc
{
    self.accountSettings = nil;
}

+ (void) load
{

}

#pragma mark -
#pragma mark ImServicePlugin

- (id) initWithServiceApplication:(id<IMServiceApplication>)serviceApplication
{
    if ((self = [super init])) {
        self.application = (id)serviceApplication;
    }
    return self;
}

- (oneway void) login
{
    NSLog(@"login");
    
    client = g_new0(struct MeanwhileClient, 1);
    
    client->application = (__bridge void *)self.application;
    
    /* set up the main session handler */
    memset(&(client->sessionHandler), 0, sizeof(client->sessionHandler));
    client->sessionHandler.io_write = sessionIoWrite;
    client->sessionHandler.io_close = sessionIoClose;
    client->sessionHandler.on_stateChange = sessionOnStateChange;
    client->sessionHandler.on_setPrivacyInfo = sessionOnSetPrivacyInfo;
    client->sessionHandler.on_setUserStatus = sessionOnSetUserStatus;
    client->sessionHandler.on_admin = sessionOnAdmin;
    client->sessionHandler.on_announce = sessionOnAnnounce;
    client->sessionHandler.clear = sessionClear;
    
    client->session = mwSession_new(&(client->sessionHandler));
    mwSession_setClientData(client->session, client, 0L);
    
    /* set up the aware service */
    memset(&(client->awareHandler), 0, sizeof(client->awareHandler));
    client->awareHandler.on_attrib = awareOnAttrib;
    client->awareHandler.clear = awareClear;
    
    client->serviceAware = mwServiceAware_new(client->session, &(client->awareHandler));
    mwSession_addService(client->session, (struct mwService *)client->serviceAware);
    
    /* create an aware list */
    memset(&(client->awareListHandler), 0, sizeof(client->awareListHandler));
    client->awareListHandler.on_aware = awareListOnAware;
    client->awareListHandler.on_attrib = awareListOnAttrib;
    client->awareListHandler.clear = awareListClear;
    
    client->awareList = mwAwareList_new(client->serviceAware, &(client->awareListHandler));
    mwAwareList_setClientData(client->awareList, client, 0L);
    
    /* set up im service */
    memset(&(client->imHandler), 0, sizeof(client->imHandler));
    client->imHandler.conversation_opened = imConversationOpened;
    client->imHandler.conversation_closed = imConversationClosed;
    client->imHandler.conversation_recv = imConversationRecv;
    client->imHandler.clear = imClear;
    
    client->serviceIm = mwServiceIm_new(client->session, &(client->imHandler));
    mwService_setClientData((struct mwService *)client->serviceIm, client, 0L);
    mwSession_addService(client->session, (struct mwService *) client->serviceIm);
    
    /* add resolve service */
    client->serviceResolve = mwServiceResolve_new(client->session);
    mwService_setClientData((struct mwService *)client->serviceResolve, client, 0L);
    mwSession_addService(client->session, (struct mwService *) client->serviceResolve);
    
    /* storage service */
    client->serviceStorage = mwServiceStorage_new(client->session);
    mwService_setClientData((struct mwService *)client->serviceStorage, client, 0L);
    mwSession_addService(client->session, (struct mwService *) client->serviceStorage);
    
    /* add a necessary cipher */
    mwSession_addCipher(client->session, mwCipher_new_RC2_40(client->session));
    mwSession_addCipher(client->session, mwCipher_new_RC2_128(client->session));
    
    /* start the login process */
    
    NSString *authToken = [self.accountSettings objectForKey:IMAccountSettingLoginHandle];
    NSString *authPass = [self.accountSettings objectForKey:IMAccountSettingPassword];
    NSString *authHost = [self.accountSettings objectForKey:IMAccountSettingServerHost];
    NSString *authPort = [self.accountSettings objectForKey:IMAccountSettingServerPort];
    
    int port = (int) [authPort integerValue];
    
    client->session = mwSession_new(&(client->sessionHandler));
    mwSession_setProperty(client->session,
                          mwSession_AUTH_USER_ID,
                          (gpointer)[authToken cStringUsingEncoding:[NSString defaultCStringEncoding]],
                          NULL);
    
    mwSession_setProperty(client->session,
                          mwSession_AUTH_PASSWORD,
                          (gpointer)[authPass cStringUsingEncoding:[NSString defaultCStringEncoding]],
                          NULL);
    
    mwSession_setClientData(client->session, client, g_free);
    
    client->sock = initiateSocket((char *)[authHost cStringUsingEncoding:[NSString defaultCStringEncoding]], port);
    
    mwSession_start(client->session);
}

- (oneway void) logout
{
    NSLog(@"logout");
    
    enum mwSessionState state = mwSession_getState(client->session);
    if (state != mwSession_STOPPED && state != mwSession_STOPPING) {
        mwSession_stop(client->session, ERR_SUCCESS);
    }
    
    mwSession_removeService(client->session, mwService_STORAGE);
    mwSession_removeService(client->session, mwService_RESOLVE);
    mwSession_removeService(client->session, mwService_IM);
    mwSession_removeService(client->session, mwService_AWARE);
    
    mwAwareList_free(client->awareList);
    mwService_free(MW_SERVICE(client->serviceStorage));
    mwService_free(MW_SERVICE(client->serviceResolve));
    mwService_free(MW_SERVICE(client->serviceIm));
    mwService_free(MW_SERVICE(client->serviceAware));
    mwCipher_free(mwSession_getCipher(client->session, mwCipher_RC2_40));
    mwCipher_free(mwSession_getCipher(client->session, mwCipher_RC2_128));
    
    mwSession_free(client->session);
    
    client->application = NULL;
    
    g_free(client);
    
    [self.application plugInDidLogOutWithError:nil reconnect:NO];
}

- (oneway void) updateAccountSettings:(NSDictionary *)accountSettings
{
    NSLog(@"updateAccountSettings: %@", accountSettings);
    
    self.accountSettings = accountSettings;
}

#pragma mark -
#pragma mark IMServicePluginChatroomSupport

- (oneway void) joinChatRoom:(NSString *)roomName
{
    NSLog(@"joinChatRoot: %@", roomName);
}

- (oneway void) leaveChatRoom:(NSString *)roomName
{
    NSLog(@"leaveChatRoot: %@", roomName);
}

- (oneway void) inviteHandles:(NSArray *)handles toChatRoom:(NSString *)roomName withMessage:(IMServicePlugInMessage *)message
{
    NSLog(@"inviteHandles");
}

- (oneway void) sendMessage:(IMServicePlugInMessage *)message toChatRoom:(NSString *)roomName
{
    NSLog(@"sendMessage: %@ toHandleOrChatRoom: %@", [message content], roomName);
}

- (oneway void) declineChatRoomInvitation:(NSString *)roomName
{
    NSLog(@"declineChatRoomInvitation: %@", roomName);
}

#pragma mark -
#pragma mark IMServiceApplicationInstantMessagingSupport

- (oneway void) userDidStartTypingToHandle:(NSString *)handle
{
    NSLog(@"userDidStartTypingToHandle: %@", handle);
}

- (oneway void) userDidStopTypingToHandle:(NSString *)handle
{
    NSLog(@"userDidStopTypingToHandle: %@", handle);
}


- (oneway void) sendMessage:(IMServicePlugInMessage *)message toHandle:(NSString *)handle
{
    NSLog(@"sendMessage: %@ toHandle: %@", message, handle);
}

@end
