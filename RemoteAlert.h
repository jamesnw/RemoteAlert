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
//  RemoteAlert.h
//  RemoteReminder
//
//  Created by James Stuckey Weber on 5/6/12.
//  Copyright (c) 2012 ChinStr.apps. All rights reserved.
//
extern NSString *const kRemoteAlertFirstUseDate;
extern NSString *const kRemoteAlertUseCount;
extern NSString *const kRemoteAlertSignificantEventCount;
extern NSString *const kRemoteAlertCurrentVersion;
extern NSString *const kRemoteAlertRatedCurrentVersion;
extern NSString *const kRemoteAlertDeclinedToRate;
extern NSString *const kRemoteAlertReminderRequestDate;
extern NSString *const kRemoteAlertLastMessageVersion;

#define REMOTEALERT_ALERT_LOCATION @"http://up.jamesnweber.com/_chinstrapps/remoteAlert/BIABCalc/RemoteAlert.json"
/*
 Users will need to have the same version of your app installed for this many
 days before they will be prompted to rate it.
 */
#define REMOTEALERT_DAYS_UNTIL_PROMPT		30		// double

#define REMOTEALERT_USES_UNTIL_PROMPT		20		// integer

#define REMOTEALERT_TIME_BEFORE_REPEAT		1	// double

#define REMOTEALERT_DEBUG					YES

@interface RemoteAlert : NSObject <UIAlertViewDelegate>{
	UIAlertView *remoteAlert;
}
@property (nonatomic, retain) UIAlertView *remoteAlert;
@property (nonatomic, retain) NSString *link;
+ (void)appLaunched:(BOOL)canShowAlert;
+ (void)appEnteredForeground:(BOOL)canShowAlert;

@end
