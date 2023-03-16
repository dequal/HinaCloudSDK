//
// MessageQueueBySqlite.h
// HinaDataSDK
//
// Created by hina on 15/7/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNEventRecord.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @abstract
 * 一个基于Sqlite封装的接口，用于向其中添加和获取数据
 */
@interface HNDatabase : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@property (nonatomic, assign, readonly) BOOL isCreatedTable;

@property (nonatomic, assign, readonly) NSUInteger count;

/// init method
/// @param filePath path for database file
- (instancetype)initWithFilePath:(NSString *)filePath;


/// open database, return YES or NO
- (BOOL)open;


/// create default event table, return YES or NO
- (BOOL)createTable;

/// fetch first records with a certain size
/// @param recordSize record size
/// @param instantEvent instant event or not
- (NSArray<HNEventRecord *> *)selectRecords:(NSUInteger)recordSize isInstantEvent:(BOOL)instantEvent;


/// bulk insert event records
/// @param records event records
- (BOOL)insertRecords:(NSArray<HNEventRecord *> *)records;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(HNEventRecord *)record;

/// update records' status
/// @param recordIDs event recordIDs
/// @param status status
- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(HNEventRecordStatus)status;

- (NSUInteger)recordCountWithStatus:(HNEventRecordStatus)status;

/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete first records with a certain size
/// @param recordSize record size
- (BOOL)deleteFirstRecords:(NSUInteger)recordSize;


/// delete all records from database
- (BOOL)deleteAllRecords;

@end

NS_ASSUME_NONNULL_END
