/*
 This file is part of RemoteAlert.
 
 Copyright (c) 2012, James Stuckey Weber
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
//
//  RemoteAlert.m
//  RemoteReminder
//
//  Created by James Stuckey Weber on 5/6/12.
//  Copyright (c) 2012 ChinStr.apps. All rights reserved.
//
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "RemoteAlert.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

NSString *const kRemoteAlertFirstUseDate				= @"kRemoteAlertFirstUseDate";
NSString *const kRemoteAlertUseCount					= @"kRemoteAlertUseCount";
NSString *const kRemoteAlertSignificantEventCount		= @"kRemoteAlertSignificantEventCount";
NSString *const kRemoteAlertCurrentVersion			= @"kRemoteAlertCurrentVersion";
NSString *const kRemoteAlertReminderRequestDate		= @"kRemoteAlertReminderRequestDate";
NSString *const kRemoteAlertLastMessageVersion		= @"kRemoteAlertLastMessageVersion";

@interface RemoteAlert ()
-(BOOL)connectedToNetwork;
+ (RemoteAlert*)sharedInstance;
-(void)fetchRemoteAlert;
-(BOOL)alertConditionsHaveBeenMet;
-(void)incrementUseCount;
-(void)hideRemoteAlert;
@end

@implementation RemoteAlert

@synthesize remoteAlert, link;

- (BOOL)connectedToNetwork {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+ (RemoteAlert*)sharedInstance{
	static RemoteAlert *remoteAlert = nil;
	if(remoteAlert == nil){
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
            remoteAlert = [[RemoteAlert alloc] init];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:
			 UIApplicationWillResignActiveNotification object:nil];
        });
	}
	
	return remoteAlert;
}
-(void) fetchRemoteAlert {
	dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:REMOTEALERT_ALERT_LOCATION]];
        if(data != nil)
		[self performSelectorOnMainThread:@selector(showAlert:) 
							   withObject:data waitUntilDone:YES];
    });
}
-(void)showAlert:(NSData *)responseData{
	//parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
						  JSONObjectWithData:responseData
						  options:kNilOptions 
						  error:&error];
	NSString *show = [json objectForKey:@"show"];
	NSString *title = [json objectForKey:@"title"];
	NSString *message = [json objectForKey:@"message"];
	self.link = [json objectForKey:@"link"];
	NSString *acceptButtonTitle = [json objectForKey:@"acceptButtonTitle"];
	NSString *cancelButtonTitle = [json objectForKey:@"cancelButtonTitle"];
	
	NSString *alertVersion = [json objectForKey:@"version"]; 
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *oldVersion = [userDefaults stringForKey:kRemoteAlertLastMessageVersion];
	

	NSLog(@"Version:%@,OldVersion:%@",alertVersion,oldVersion);
	if(![alertVersion isEqualToString:oldVersion]){
		NSLog(@"test");
	[userDefaults setObject:alertVersion forKey:kRemoteAlertLastMessageVersion];
	if([show isEqualToString:@"YES"]){
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:acceptButtonTitle, nil];
		self.remoteAlert = alertView;
		[alertView show];
	}
		}
}
-(BOOL)alertConditionsHaveBeenMet{
	if(REMOTEALERT_DEBUG)
		return YES;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	// Check if enough time since first launch has passed
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kRemoteAlertFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRate = 60 * 60 * 24 * REMOTEALERT_DAYS_UNTIL_PROMPT;
	if (timeSinceFirstLaunch < timeUntilRate)
		return NO;
	
	// check if the app has been used enough
	int useCount = [userDefaults integerForKey:kRemoteAlertUseCount];
	if (useCount <= REMOTEALERT_USES_UNTIL_PROMPT)
		return NO;
	
	return YES;
}
	
-(void)incrementUseCount {
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kRemoteAlertCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kRemoteAlertCurrentVersion];
	}
	if (REMOTEALERT_DEBUG)
		NSLog(@"REMOTEALERT Tracking version: %@", trackingVersion);
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kRemoteAlertFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kRemoteAlertFirstUseDate];
		}
		
		// increment the use count
		int useCount = [userDefaults integerForKey:kRemoteAlertUseCount];
		useCount++;
		[userDefaults setInteger:useCount forKey:kRemoteAlertUseCount];
		if (REMOTEALERT_DEBUG)
			NSLog(@"RemoteAlert Use count: %d", useCount);
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kRemoteAlertCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kRemoteAlertFirstUseDate];
		[userDefaults setInteger:1 forKey:kRemoteAlertUseCount];
		[userDefaults setInteger:0 forKey:kRemoteAlertSignificantEventCount];	
		[userDefaults setDouble:0 forKey:kRemoteAlertReminderRequestDate];
		[userDefaults setObject:@"-1" forKey:kRemoteAlertLastMessageVersion];
	}
	
	[userDefaults synchronize];
}
- (void)incrementAndRate:(BOOL)canShowAlert{
	[self incrementUseCount];
	if (canShowAlert && [self alertConditionsHaveBeenMet] && [self connectedToNetwork]){
		dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self fetchRemoteAlert];
                       });

	}
}
+ (void)appLaunched:(BOOL)canShowAlert {
	NSLog(@"appLaunched");
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[RemoteAlert sharedInstance] incrementAndRate:canShowAlert];
                   });
}
- (void)hideRatingAlert {
	if (self.remoteAlert.visible) {
		if (REMOTEALERT_DEBUG)
			NSLog(@"RemoteAlert Hiding Alert");
		[self.remoteAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}	
}

+ (void)appWillResignActive {
	if(REMOTEALERT_DEBUG)
		NSLog(@"RemoteAlert appWillResignActive");
	[[RemoteAlert sharedInstance] hideRemoteAlert];
}
+ (void)appEnteredForeground:(BOOL)canShowAlert {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[RemoteAlert sharedInstance] incrementAndRate:canShowAlert];
                   });
}	
	
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	//NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	switch (buttonIndex) {
		case 0:
		{
			//Cancel
			break;
		}
		case 1:
		{
			// Accept
			NSURL *url = [NSURL URLWithString:self.link];
			[[UIApplication sharedApplication] openURL:url];
			break;
		}
		default:
			break;
	}

}
	
- (void)hideRemoteAlert {
	if (self.remoteAlert.visible) {
		if (REMOTEALERT_DEBUG)
			NSLog(@"REMOTEALERT Hiding Alert");
		[self.remoteAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}	
}	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


@end
