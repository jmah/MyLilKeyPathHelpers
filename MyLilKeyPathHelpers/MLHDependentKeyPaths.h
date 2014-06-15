//
//  MLHDependentKeyPaths.h
//  MyLilKeyPathHelpers
//
//  Created by Jonathon Mah on 2014-03-01.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Given the key \p foo, returns the key-value observing dependency selector
 * \p keyPathsForValuesAffectingFoo. */
SEL MLHDependentKeySelectorForKey(NSString *key);


/** Calls \p +keyPathsForValuesAffectingValueForKey: on the defining class's superclass.
 * Use this when overriding a key in a subclass, for example:
 *
 \code
+ (NSSet *)keyPathsForValuesAffectingMyProperty
{
    return [MLHSuperclassKeyPathsAffecting(_definingClass, @"myProperty")
            setByAddingObject:@"somethingElse"];
}
- (BOOL)myProperty
{
    return [super myProperty] || [self somethingElse];
}
 \endcode
 */
NSSet *MLHSuperclassKeyPathsAffecting(Class definingClass, NSString *key);


/** This function contains logic to correctly override the \p +keyPathsForValuesAffectingValueForKey:
 * method. This method is complicated to override because subclasses could be overriding either
 * \p +keyPathsForValuesAffectingValueForKey: or \p +keyPathsForValuesAffectingSpecificKey. An
 * override of the former will act as normal, but an override of a specific key will be found when
 * calling up to \p NSObject's implementation. In other words, calling
 * \p [super keyPathsForValuesAffectingValueForKey:key] may or may not include subclass changes,
 * depending on how the subclass specified the dependencies.
 *
 * Additionally, calling \p [super keyPathsForValuesAffectingValueForKey:key] may call a subclass's
 * \p +keyPathsForValuesAffectingSpecificKey method, which may contain a call back to
 * \p [super keyPathsForValuesAffectingValueForKey:key] — causing the implementation to be run
 * twice. Or a subclass could choose \em not to call super, in which case this method shouldn't
 * affect what the subclass wants to return.
 *
 * This method determines whether customization of super's set is appropriate and, if so, calls the
 * block argument to perform the changes.
 *
 \code
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    return MLHOverrideKeyPathsForValueAffectingKey(self, _definingClass, NO, key, ^(NSSet *superKeyPaths) {
        if ([self shouldAddDependentKeyPathTo:key]) {
            return [superKeyPaths setByAddingObject:@"anotherKey"];
        } else if ([self shouldReplaceDependentKeyPathsOf:key]) {
            return [NSSet setWithObject:@"newKey"];
        } else {
            return superKeyPaths;
        }
    });
}
 \endcode
 *
 * \param self the class whose dependent key paths are being queried; pass \p self.
 *
 * \param definingClass the class implementing the \p +keyPathsForValuesAffectingValueForKey: method;
 * specify the class of the enclosing \p \@implementation, or use the \p _definingClass macro.
 * (Do not pass \c self .)
 *
 * \param affectOwnKeys whether \p customizeBlock should be called for key-specific methods
 * (e.g. \p +keyPathsForValuesAffectingSpecificKey ) implemented by this class, or only superclasses.
 * Note that this \em can be a dynamic value that depends on the value of \p key.
 *
 * \param key the key being queried
 *
 * \param customizeBlock a block that's called when appropriate to customize the return value. It is
 * passed the key paths affecting \p key in the superclass, and should return the key paths
 * affecting \p key in this class.
 *
 * \returns the key paths affecting \p key of \p self
 */
NSSet *MLHOverrideKeyPathsForValueAffectingKey(Class self, Class definingClass, BOOL affectOwnKeys, NSString *key, NSSet *(^customizeBlock)(NSSet *superKeyPaths)) __attribute__((nonnull));
