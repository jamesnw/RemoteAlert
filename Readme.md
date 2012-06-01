Introduction
------------
RemoveAlert is a class that you can drop into any iPhone app that allows you to remotely trigger custom alerts. This can be useful to remind users of important updates, or to inform them of a new product. It is based heavily on [Appirater](https://github.com/arashpayan/appirater).  The code is released under the MIT/X11, so feel free to modify and share your changes with the world. To find out more, check out the [project homepage](https://github.com/jamesnw/RemoteAlert).

Getting Started
---------------
1. Add the RemoteAlert code into your project
2. Add the `CFNetwork` and `SystemConfiguration` frameworks to your project
3. Call `[RemoteAlert appLaunched:YES]` at the end of your app delegate's `application:didFinishLaunchingWithOptions:` method.
4. Call `[RemoteAlert appEnteredForeground:YES]` in your app delegate's `applicationWillEnterForeground:` method.
5. Set the `REMOTEALERT_ALERT_LOCATION` in `RemoteAlert.h` to the URL of a json file on a web server.

The JSON File
-------------
The JSON file on your website has the following fields-

1. "show" - "YES" to show an alert, "NO" to not show the alert
2. "title" - the title of the alert
3. "message"- the subtitle message of the alert
4. "link" - the link the acceptButton will take the user to. This can use any url schema, including http, fb, itms, etc.
5. "acceptButtonTitle" - the text of the acceptButton
6. "cancelButtonTitle" - the text of the button that will do nothing
7. "version" - a unique ID for the alert. This helps the RemoteAlert class differentiate between alerts, so users see new alerts, but not repeatedly see old alerts. While this can a string, the easiest way to use this is to simply increment an integer for each new alert.

Apps Using RemoteAlert
----------------------
For a list of Apps using RemoteAlert, check out [the Wiki Page.](https://github.com/jamesnw/RemoteAlert/wiki/Apps-using-RemoteAlert)

License
-------
Copyright 2012. [James Stuckey Weber] (https://github.com/jamesnw/).
This library is distributed under the terms of the MIT/X11.