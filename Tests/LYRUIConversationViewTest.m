//
//  LYRUIConversationViewTest.m
//  LayerSample
//
//  Created by Kevin Coleman on 9/16/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LYRUITestInterface.h"
#import "LYRUISampleConversationViewController.h"
#import "LYRUserMock.h"
#import "LYRUITestMessageCollectionViewCell.h"

@interface LYRUIConversationViewController ()

@property (nonatomic) LYRQueryController *queryController;

@end

@interface LYRUIConversationViewTest : XCTestCase

@property (nonatomic) LYRUITestInterface *testInterface;
@property (nonatomic) LYRUISampleConversationViewController *viewController;
@property (nonatomic) LYRConversationMock *conversation;

@end

@implementation LYRUIConversationViewTest

- (void)setUp
{
    [super setUp];

    LYRUserMock *mockUser = [LYRUserMock userWithMockUserName:LYRClientMockFactoryNameRussell];
    LYRClientMock *layerClient = [LYRClientMock layerClientMockWithAuthenticatedUserID:mockUser.participantIdentifier];
    self.testInterface = [LYRUITestInterface testIntefaceWithLayerClient:layerClient];
    
    LYRUserMock *mockUser1 = [LYRUserMock userWithMockUserName:LYRClientMockFactoryNameMarshawn];
    self.conversation = [self.testInterface conversationWithParticipants:[NSSet setWithObject:mockUser1.participantIdentifier] lastMessageText:nil];
}

- (void)tearDown
{
    [[LYRMockContentStore sharedStore] resetContentStore];
    self.viewController.queryController = nil;
    self.testInterface = nil;
    
    [super tearDown];
}

//Send a new message a verify it appears in the view.
- (void)testToVerifySentMessageAppearsInConversationView
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    [self sendMessageWithText:@"This is a test"];
}

//Synchronize a new message and verify it appears in the view.
- (void)testToVerifyRecievedMessageAppearsInConversationView
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    LYRMessagePart *part = [LYRMessagePart messagePartWithText:@"Hey Dude"];
    LYRMessageMock *message = [LYRMessageMock newMessageWithParts:@[part] senderID:[LYRUserMock userWithMockUserName:LYRClientMockFactoryNameMarshawn].participantIdentifier];
    [self.conversation sendMessage:message error:nil];
    
    [tester waitForViewWithAccessibilityLabel:@"Hey Dude"];
}

//Add an image to a message and verify that it sends.
- (void)testToVerifySentImageAppearsInConversationView
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    [self sendPhotoMessage];
}

- (void)testToVerifyCorrectCellIsReturnedForMessage
{
    LYRMessagePartMock *messagePart1 = [LYRMessagePartMock messagePartWithText:@"How are you1?"];
    LYRMessageMock *message1 = [self.testInterface.layerClient newMessageWithParts:@[messagePart1] options:nil error:nil];
    [self.conversation sendMessage:message1 error:nil];
    
    LYRMessagePartMock *messagePart2 = [LYRMessagePartMock messagePartWithText:@"How are you2?"];
    LYRMessageMock *message2 = [self.testInterface.layerClient newMessageWithParts:@[messagePart2] options:nil error:nil];
    [self.conversation sendMessage:message2 error:nil];

    LYRMessagePartMock *messagePart3 = [LYRMessagePartMock messagePartWithText:@"How are you3?"];
    LYRMessageMock *message3 = [self.testInterface.layerClient newMessageWithParts:@[messagePart3] options:nil error:nil];
    [self.conversation sendMessage:message3 error:nil];

    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    id cell = [self.viewController collectionViewCellForMessage:(LYRMessage *)message3];
    expect([cell class]).to.beSubclassOf([LYRUIMessageCollectionViewCell class]);
    expect([cell accessibilityLabel]).to.equal(@"Message: How are you3?");
}

//- (void)conversationViewController:(LYRUIConversationViewController *)viewController didSendMessage:(LYRMessage *)message;
- (void)testToVerifyDelegateIsNotifiedOfMessageSend
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    id delegateMock = OCMProtocolMock(@protocol(LYRUIConversationViewControllerDelegate));
    self.viewController.delegate = delegateMock;
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {

    }] conversationViewController:[OCMArg any] didSendMessage:[OCMArg any]];
    
    [self sendMessageWithText:@"This is a test"];
    [delegateMock verify];
}

//- (void)conversationViewController:(LYRUIConversationViewController *)viewController didSelectMessage:(LYRMessage *)message;
- (void)testToVerifyDelegateIsNotifiedOfMessageSelection
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    id delegateMock = OCMProtocolMock(@protocol(LYRUIConversationViewControllerDelegate));
    self.viewController.delegate = delegateMock;
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
       
    }] conversationViewController:[OCMArg any] didSelectMessage:[OCMArg any]];
    
    [self sendMessageWithText:@"This is a test"];
    [tester tapViewWithAccessibilityLabel:@"Message: This is a test"];
    [delegateMock verify];
}

- (void)testToVerityControllerDisplaysCorrectDataFromTheDataSource
{
    self.viewController = [LYRUISampleConversationViewController conversationViewControllerWithConversation:(LYRConversation *)self.conversation layerClient:(LYRClient *)self.testInterface.layerClient];
    [self setRootViewController:self.viewController];
    
    id delegateMock = OCMProtocolMock(@protocol(LYRUIConversationViewControllerDataSource));
    self.viewController.dataSource = delegateMock;
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Gift"];
        [invocation setReturnValue:&string];
    }] conversationViewController:[OCMArg any] attributedStringForDisplayOfDate:[OCMArg any]];
    
    // Three call to get date string
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Date String"];
        [invocation setReturnValue:&string];
    }] conversationViewController:[OCMArg any] attributedStringForDisplayOfRecipientStatus:[OCMArg any]];
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Date String"];
        [invocation setReturnValue:&string];
    }] conversationViewController:[OCMArg any] attributedStringForDisplayOfRecipientStatus:[OCMArg any]];
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Date String"];
        [invocation setReturnValue:&string];
    }] conversationViewController:[OCMArg any] attributedStringForDisplayOfRecipientStatus:[OCMArg any]];
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSString *pushText = @"Test Push Text";
        [invocation setReturnValue:&pushText];
    }] conversationViewController:[OCMArg any] pushNotificationTextForMessagePart:[OCMArg any]];
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        float yes = 1.0f;
        [invocation setReturnValue:&yes];
    }] conversationViewController:[OCMArg any] shouldUpdateRecipientStatusForMessage:[OCMArg any]];
    
    [[[delegateMock expect] andDo:^(NSInvocation *invocation) {
        NSString *identifer = @"LYRUIOutgoingMessageCellIdentifier";
        [invocation setReturnValue:&identifer];
    }] conversationViewController:[OCMArg any] reuseIdentifierForMessage:[OCMArg any]];
    
    [self sendMessageWithText:@"This is a test"];
    [delegateMock verify];
}

- (void)sendMessageWithText:(NSString *)messageText
{
    [tester enterText:messageText intoViewWithAccessibilityLabel:@"Text Input View"];
    [tester tapViewWithAccessibilityLabel:@"Send Button"];
    [tester waitForViewWithAccessibilityLabel:[NSString stringWithFormat:@"%@", messageText]];
}

- (void)sendPhotoMessage
{
    [tester tapViewWithAccessibilityLabel:@"Camera Button"];
    [tester tapViewWithAccessibilityLabel:@"Photo Library"];
    [tester tapViewWithAccessibilityLabel:@"Camera Roll"];
    [tester tapViewWithAccessibilityLabel:@"Photo, Landscape, July 13, 9:28 PM"];
    [tester tapViewWithAccessibilityLabel:@"Send Button"];
    [tester waitForViewWithAccessibilityLabel:[NSString stringWithFormat:@"Message: Photo"]];
}

- (void)setRootViewController:(UIViewController *)controller
{
    [self.testInterface setRootViewController:controller];
    [tester waitForTimeInterval:1];
}

@end