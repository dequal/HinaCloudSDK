//
// HNFlushHTTPBodyInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlushHTTPBodyInterceptor.h"
#import "NSString+HNHashCode.h"
#import "HNGzipUtility.h"
#import "HNEventRecord.h"
#import "HNJSONUtil.h"

@interface HNConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

@implementation HNFlushHTTPBodyInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);
    
    input.HTTPBody = [self buildBodyWithInput:input];
    completion(input);
}

// 2. 完成 HTTP 请求拼接
- (NSData *)buildBodyWithInput:(HNFlowData *)input {
    BOOL isEncrypted = input.configOptions.enableEncrypt && input.records.firstObject.isEncrypted;
    NSString *jsonString = input.json;
    int gzip = 1; // gzip = 2 表示加密编码
    if (isEncrypted) {
        // 加密数据已{经做过 gzip 压缩和 base64 处理了，就不需要再处理。
        gzip = 2;
    } else {
        // 使用gzip进行压缩
        NSData *zippedData = [HNGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        // base64
        jsonString = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    int hashCode = [jsonString hinadata_hashCode];
    //    jsonString = [jsonString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    //进行urldecode
    
    //    NSString *bodyString = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, jsonString];
    //    if (input.isInstantEvent) {
    //        bodyString = [bodyString stringByAppendingString:@"&instant_event=true"];
    //    }
    //    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    //    [dict setValue:@"BHRfsTQS" forKey:@"token"]; //yt888  BHRfsTQS
    [dict setValue:@(hashCode) forKey:@"crc"];
    [dict setValue:jsonString forKey:@"data"];
    [dict setValue:@"gzip" forKey:@"compress"];
    if (gzip == 2) {
        [dict setValue:@"aes" forKey:@"encrypt"];
    } else {
        [dict setValue:@"" forKey:@"encrypt"];
    }
    if (input.isInstantEvent) {
        [dict setValue:@(true) forKey:@"instant_event"];
    }
    
    NSData *data = [[NSData alloc] init];
    if (@available(iOS 13.0, *)) {
        data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingWithoutEscapingSlashes error:nil];
        return  data;
    }else {
        data= [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
        if(!data ){
            return data;
        }
        //NSJSONSerialization converts a URL string from http://... to http:\/\/... remove the extra escapes
        NSString *policyStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        policyStr = [policyStr stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        data = [policyStr dataUsingEncoding:NSUTF8StringEncoding];
        return data;
    }
    //    return data;
    
}


@end
