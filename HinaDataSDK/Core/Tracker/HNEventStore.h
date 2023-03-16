//
// HNEventStore.h
// HinaDataSDK
//
// Created by hina on 2022/6/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import "HNEventRecord.h"

NS_ASSUME_NONNULL_BEGIN

/// 默认存储表名和文件名
extern NSString * const kHNDatabaseNameKey;
extern NSString * const kHNDatabaseDefaultFileName;

@interface HNEventStore : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

/// All event record count
@property (nonatomic, readonly) NSUInteger count;

/**
 *  @abstract
 *  根据传入的文件路径初始化
 *
 *  @param filePath 传入的数据文件路径
 *
 *  @return 初始化的结果
 */
- (instancetype)initWithFilePath:(NSString *)filePath;

+ (instancetype)eventStoreWithFilePath:(NSString *)filePath;

/// fetch first records with a certain size
/// @param recordSize record size
/// @param instantEvent instant event or not
- (NSArray<HNEventRecord *> *)selectRecords:(NSUInteger)recordSize isInstantEvent:(BOOL)instantEvent;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(HNEventRecord *)record;


- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(HNEventRecordStatus)status;


/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete all records from database
- (BOOL)deleteAllRecords;

- (NSUInteger)recordCountWithStatus:(HNEventRecordStatus)status;

@end

NS_ASSUME_NONNULL_END
