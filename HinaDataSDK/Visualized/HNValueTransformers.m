//
// HNValueTransformers.m
// HinaDataSDK
//
// Created by hina on 1/20/16
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "HNLog.h"
#import "HNValueTransformers.h"

#pragma mark -- PassThrough

@implementation HNPassThroughValueTransformer

+ (Class)transformedValueClass {
    return [NSObject class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) {
        return nil;
    }
    return value;
}

@end

#pragma mark -- BOOL To NSNumber

@implementation HNBOOLToNSNumberValueTransformer

+ (Class)transformedValueClass {
    return [@YES class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue] ? @YES : @NO;
    }
    
    return nil;
}

@end


#pragma mark -- CGPoint To NSDictionary

@implementation HNCGPointToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGPointValue)]) {
        CGPoint point = [value CGPointValue];
        point.x = isnormal(point.x) ? point.x : 0.0f;
        point.y = isnormal(point.y) ? point.y : 0.0f;
        return CFBridgingRelease(CGPointCreateDictionaryRepresentation(point));
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    CGPoint point = CGPointZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &point)) {
        return [NSValue valueWithCGPoint:point];
    }
    
    return [NSValue valueWithCGPoint:CGPointZero];
}

@end

#pragma mark -- CGRect To NSDictionary

@implementation HNCGRectToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (![value respondsToSelector:@selector(CGRectValue)]) {
        return nil;
    }
    CGRect rect = [value CGRectValue];
    rect.origin.x = isnormal(rect.origin.x) ? rect.origin.x : 0.0f;
    rect.origin.y = isnormal(rect.origin.y) ? rect.origin.y : 0.0f;
    rect.size.width = isnormal(rect.size.width) ? rect.size.width : 0.0f;
    rect.size.height = isnormal(rect.size.height) ? rect.size.height : 0.0f;
    return CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect));
}

- (id)reverseTransformedValue:(id)value {
    CGRect rect = CGRectZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &rect)) {
        return [NSValue valueWithCGRect:rect];
    }
    
    return [NSValue valueWithCGRect:CGRectZero];
}

@end

#pragma mark -- CGSize To NSDictionary

@implementation HNCGSizeToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGSizeValue)]) {
        CGSize size = [value CGSizeValue];
        size.width = isnormal(size.width) ? size.width : 0.0f;
        size.height = isnormal(size.height) ? size.height : 0.0f;
        return CFBridgingRelease(CGSizeCreateDictionaryRepresentation(size));
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    CGSize size = CGSizeZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGSizeMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &size)) {
        return [NSValue valueWithCGSize:size];
    }
    
    return [NSValue valueWithCGSize:CGSizeZero];
}

@end




