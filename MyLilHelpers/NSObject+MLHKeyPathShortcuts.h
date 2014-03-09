//
//  NSObject+MLHKeyPathShortcuts.h
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-03-08.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIApplication.h>)
#   import <UIKit/UIApplication.h>
#   define MLH_APP_CLASS UIApplication
#elif __has_include(<AppKit/NSApplication.h>)
#   import <AppKit/NSApplication.h>
#   define MLH_APP_CLASS NSApplication
#endif


/** MLHKeyPathShortcuts adds accessors to \p NSObject to make it easy to express key-value observing
 * dependencies with external objects. Consider the method:
 *
 \code
- (BOOL)someFeatureEnabled
{
    return self.someFeatureEnabledLocally &&
           [[NSUserDefaults standardUserDefaults] boolForKey:@"someFeatureEnabledGlobally"];
}
 \endcode
 *
 * Using MLHKeyPathShortcuts methods, the following dependency method will trigger the correct
 * notifications for \p someFeatureEnabled :
 *
 \code
+ (NSSet *)keyPathsForValuesAffectingSomeFeatureEnabled
{
    return [NSSet setWithObjects:@"someFeatureEnabledLocally", @"$defaults.someFeatureEnabledGlobally", nil];
}
 \endcode
 *
 * \p $classes is the core accessor, enabling key-value coding access to Objective-C classes. For
 * example, \p [someObject valueForKeyPath:\@"$classes.NSNotificationCenter.defaultCenter"] will
 * return the same value as \p [NSNotificationCenter defaultCenter].
 *
 * Additionally, two accessors are provided for common keys: \p $defaults for
 * \p [NSUserDefaults standardUserDefaults] , and \p $app for the shared \p NSApplication or
 * \p UIApplication instance. (You can specify a dependence on \p $app.delegate.someValue .)
 */
@interface NSObject (MLHKeyPathShortcuts)

- (id)$classes;

- (NSUserDefaults *)$defaults;

#ifdef MLH_APP_CLASS
- (MLH_APP_CLASS *)$app;
#endif

@end
