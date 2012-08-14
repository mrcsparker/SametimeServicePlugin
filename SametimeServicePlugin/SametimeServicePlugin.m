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

static void readSocketCallback(CFSocketRef s,
                               CFSocketCallBackType type,
                               CFDataRef address,
                               const void *data,
                               void *info)
{
    NSLog(@"readSocketCallback");
    
    CFDataRef df = (CFDataRef) data;
    long len = CFDataGetLength(df);
    
    struct mwSession *session = info;
    
    if (len <= 0) {
        NSLog(@"No data");
        return;
    }
    
    CFRange range = CFRangeMake(0, len);
    
    UInt8 buffer[len];
    
    CFDataGetBytes(df, range, buffer);
    
    mwSession_recv(session, buffer, len);
}


CFSocketRef initiateSocket(const char *host, int port, struct mwSession *session)
{
    NSLog(@"initiateSocket");
    
    CFSocketRef s = NULL;
    CFSocketContext cxt = { 0, session, NULL, NULL, NULL };
    struct sockaddr_in addr;
    struct hostent *hostinfo;
    
    s = CFSocketCreate(kCFAllocatorDefault,
                       PF_INET,
                       SOCK_STREAM,
                       IPPROTO_TCP,
                       kCFSocketAcceptCallBack,
                       readSocketCallback,
                       &cxt);

    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    hostinfo = gethostbyname(host);
    if (hostinfo == NULL) {
        NSLog(@"Unknown host %s", host);
        exit(1);
    }
    addr.sin_addr = *(struct in_addr *) hostinfo->h_addr;

    CFDataRef address = CFDataCreate(NULL, (UInt8 *)&addr, sizeof(addr));
    CFSocketError error = CFSocketConnectToAddress(s, address, 0);
    if (error < 0) {
        NSLog(@"initiateSocket: error connecting to server");
        exit(1);
    }
    CFRelease(address);
    
    return s;
    
}

static int sessionIoWrite(struct mwSession *session, const guchar *buf, gsize len)
{
    
    NSLog(@"sessionIoWrite: %s", buf);
    
    struct MeanwhileClient *client;
    long ret = 0;
    
    client = mwSession_getClientData(session);
    
    g_return_val_if_fail(client != NULL, -1);
    
    
    if (client->sock == NULL) {
        return -1;
    }
    
    if (len > 0) {
        CFDataRef data = CFDataCreate(NULL, buf, len);
        CFSocketSendData(client->sock, NULL, data, 0);
        CFRelease(data);
    }
    
    return 0;
}

static void sessionIoClose(struct mwSession *session)
{
    struct MeanwhileClient *client;
    
    client = mwSession_getClientData(session);
    
    g_return_if_fail(client != NULL);
    
    if (client->sock) {
        
    }
}

static void sessionOnStateChange(struct mwSession *session, enum mwSessionState state, gpointer info)
{
    struct MeanwhileClient *client;
    
    client = mwSession_getClientData(session);
    
    switch (state) {
        case mwSession_STARTING:
            NSLog(@"[2] Sending Handshake");
            break;
        case mwSession_HANDSHAKE:
            NSLog(@"[3] Waiting for Handshake Acknowledgement");
            break;
        case mwSession_HANDSHAKE_ACK:
            NSLog(@"[4] Handshake Acknowledged, Sending Login");
            break;
        case mwSession_LOGIN:
            NSLog(@"[5] Waiting for Login Acknowledgement");
            break;
        case mwSession_LOGIN_REDIR:
            NSLog(@"[6] Login redirected");
            break;
        case mwSession_LOGIN_CONT:
            NSLog(@"[7] Forcing login");
            break;
        case mwSession_LOGIN_ACK:
            NSLog(@"[8] Login Acknowledged");
            break;                  
        case mwSession_STARTED:
        {
            NSLog(@"[9] Starting services");

            [(__bridge id)client->application plugInDidLogIn];
            
            struct mwUserStatus stat = { mwStatus_ACTIVE, 0, 0L };
            mwSession_setUserStatus(session, &stat);
            
            NSLog(@"[10] Connected");
            
            struct mwLoginInfo *loginInfo = mwSession_getLoginInfo(session);
            NSLog(@"Login info: %s", loginInfo->user_id);
        }
            break;
        case mwSession_STOPPING:
            NSLog(@"Stopping session");
            break;
        case mwSession_STOPPED:
            NSLog(@"Session stopped");
            break;      
        case mwSession_UNKNOWN:
            NSLog(@"Session unknown.  Your guess is as good as mine!");
            break;         
        default:
            NSLog(@"Session in unknown state.  You are in uncharted territory");
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

static void requestGroupListCallback(struct mwServiceStorage *srvc,
                                     guint32 result,
                                     struct mwStorageUnit *item,
                                     gpointer data)
{
    NSLog(@"requestGroupListCallback");
    
    struct MeanwhileClient *client = data;
    struct mwSametimeList *list;
    
    struct mwGetBuffer *buf;
    
    g_return_if_fail(result == ERR_SUCCESS);
    
    buf = mwGetBuffer_wrap(mwStorageUnit_asOpaque(item));
    
    list = mwSametimeList_new();
    mwSametimeList_get(buf, list);
    
    
    GList *groupList;
    
    for (groupList = mwSametimeList_getGroups(list); groupList; groupList = groupList->next) {
        struct mwSametimeGroup *sametimeGroup = (struct mwSametimeGroup *)groupList->data;
        
        NSLog(@"Sametime group: %s", mwSametimeGroup_getName(sametimeGroup));
    }
    
    g_list_free(groupList);
    
    mwSametimeList_free(list);
    mwGetBuffer_free(buf);
    
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
    char *userName = (char *)[authToken cStringUsingEncoding:[NSString defaultCStringEncoding]];
    char *password = (char *)[authPass cStringUsingEncoding:[NSString defaultCStringEncoding]];
    char *server = (char *)[authHost cStringUsingEncoding:[NSString defaultCStringEncoding]];
    
    NSLog(@"Logging in with %s:%d, %s, %s", server, port, userName, password);
    
    client->session = mwSession_new(&(client->sessionHandler));
    mwSession_setProperty(client->session,
                          mwSession_AUTH_USER_ID,
                          userName,
                          NULL);
    
    mwSession_setProperty(client->session,
                          mwSession_AUTH_PASSWORD,
                          password,
                          NULL);
    
    mwSession_setClientData(client->session, client, g_free);
    
    client->sock = initiateSocket(server, port, client->session);
    
    NSLog(@"[1] Connecting");
    
    mwSession_start(client->session);
    
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(NULL, client->sock, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),source, kCFRunLoopDefaultMode);
    
    CFRelease(source);
    CFRelease(client->sock);
    
    CFRunLoopRun();
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
#pragma mark IMServicePlugInGroupListSupport
- (oneway void) requestGroupList
{
    NSLog(@"requestGroupList");
    
    struct mwStorageUnit *unit = mwStorageUnit_new(mwStore_AWARE_LIST);
    mwServiceStorage_load(client->serviceStorage, unit, &requestGroupListCallback, client, NULL);

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

#pragma mark -
#pragma mark IMServicePlugInPresenceSupport

- (oneway void)updateSessionProperties:(NSDictionary *)properties
{
    NSLog(@"updateSessionProperties: %@", properties);
}

@end
