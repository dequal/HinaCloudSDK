//
// MessageQueueBySqlite.m
// HinaDataSDK
//
// Created by hina on 15/7/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <sqlite3.h>
#import "HNDatabase.h"
#import "HNLog.h"
#import "HNConstants+Private.h"
#import "HNObject+HNConfigOptions.h"

static NSString *const kHNDatabaseTableName = @"dataCache";
static NSString *const kHNDatabaseColumnStatus = @"status";
static NSString *const kHNDatabaseColumnEncrypted = @"encrypted";
static NSString *const kHNDatabaseColumnIsInstantEvent = @"is_instant_event";

static const NSUInteger kRemoveFirstRecordsDefaultCount = 100; // 超过最大缓存条数时默认的删除条数

@interface HNDatabase ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, assign) BOOL isCreatedTable;
@property (nonatomic, assign) NSUInteger count;

@property (nonatomic, assign) NSUInteger flushRecordCount;

@end

@implementation HNDatabase {
    sqlite3 *_database;
    CFMutableDictionaryRef _dbStmtCache;
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath;
        _serialQueue = dispatch_queue_create("cn.hinadata.HNDatabaseSerialQueue", DISPATCH_QUEUE_SERIAL);
        [self createStmtCache];
        [self open];
        [self createTable];
    }
    return self;
}

- (BOOL)open {
    if (self.isOpen) {
        return YES;
    }
    if (_database) {
        [self close];
    }
    if (sqlite3_open_v2([self.filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
        _database = NULL;
        HNLogError(@"Failed to open SQLite db");
        return NO;
    }
    HNLogDebug(@"Success to open SQLite db");
    self.isOpen = YES;
    return YES;
}

- (void)close {
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;

    if (_database) sqlite3_close(_database);
    _database = NULL;

    _isCreatedTable = NO;
    _isOpen = NO;
    HNLogDebug(@"%@ close database", self);
}

- (BOOL)databaseCheck {
    if (![self open]) {
        return NO;
    }
    if (![self createTable]) {
        return NO;
    }
    return YES;
}

// MARK: Internal APIs for database CRUD
- (BOOL)createTable {
    if (!self.isOpen) {
        return NO;
    }
    if (self.isCreatedTable) {
        return YES;
    }
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT)", kHNDatabaseTableName];
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        HNLogError(@"Create %@ table fail.", kHNDatabaseTableName);
        self.isCreatedTable = NO;
        return NO;
    }
    if (![self createColumn:kHNDatabaseColumnStatus inTable:kHNDatabaseTableName]) {
        HNLogError(@"Alert table %@ add %@ fail.", kHNDatabaseTableName, kHNDatabaseColumnStatus);
        self.isCreatedTable = NO;
        return NO;
    }
    // create is_instant_event column with integer type, default is 0, if instant event, then is_instant_event will be set to 1
    if (![self createColumn:kHNDatabaseColumnIsInstantEvent inTable:kHNDatabaseTableName]) {
        HNLogError(@"Alert table %@ add %@ fail.", kHNDatabaseTableName, kHNDatabaseColumnIsInstantEvent);
        self.isCreatedTable = NO;
        return NO;
    }
    self.isCreatedTable = YES;
    // 如果数据在上传过程中，App 被强杀或者 crash，可能存在状态不对的数据
    // 重置所有数据状态，重新上传
    [self resetAllRecordsStatus];
    self.count = [self messagesCount];
    HNLogDebug(@"Create %@ table success, current count is %lu", kHNDatabaseTableName, self.count);
    return YES;
}

- (NSArray<HNEventRecord *> *)selectRecords:(NSUInteger)recordSize isInstantEvent:(BOOL)instantEvent {
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    if ((self.count == 0) || (recordSize == 0)) {
        return [contentArray copy];
    }
    if (![self databaseCheck]) {
        return [contentArray copy];
    }
    NSString *query = [NSString stringWithFormat:@"SELECT id,content FROM dataCache WHERE %@ = 0 AND %@ = %d ORDER BY id ASC LIMIT %lu", kHNDatabaseColumnStatus, kHNDatabaseColumnIsInstantEvent, instantEvent ? 1 : 0, (unsigned long)recordSize];
    sqlite3_stmt *stmt = [self dbCacheStmt:query];
    if (!stmt) {
        HNLogError(@"Failed to prepare statement, error:%s", sqlite3_errmsg(_database));
        return [contentArray copy];
    }

    NSMutableArray<NSString *> *invalidRecords = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int index = sqlite3_column_int(stmt, 0);
        char *jsonChar = (char *)sqlite3_column_text(stmt, 1);
        if (!jsonChar) {
            HNLogError(@"Failed to query column_text, error:%s", sqlite3_errmsg(_database));
            [invalidRecords addObject:[NSString stringWithFormat:@"%d", index]];
            continue;
        }
        NSString *recordID = [NSString stringWithFormat:@"%d", index];
        NSString *content = [NSString stringWithUTF8String:jsonChar];
        HNEventRecord *record = [[HNEventRecord alloc] initWithRecordID:recordID content:content];
        [contentArray addObject:record];
    }
    [self deleteRecords:invalidRecords];

    return [contentArray copy];
}

- (BOOL)resetAllRecordsStatus {
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %d WHERE %@ = (%d);", kHNDatabaseTableName, kHNDatabaseColumnStatus, HNEventRecordStatusNone, kHNDatabaseColumnStatus, HNEventRecordStatusFlush];
    return [self execUpdateSQL:sql];
}

- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(HNEventRecordStatus)status {
    if (status == HNEventRecordStatusFlush) {
        self.flushRecordCount += recordIDs.count;
    } else {
        self.flushRecordCount -= recordIDs.count;
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %d WHERE id IN (%@);", kHNDatabaseTableName, kHNDatabaseColumnStatus, status, [recordIDs componentsJoinedByString:@","]];
    return [self execUpdateSQL:sql];
}

- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs atColumn:(NSString *)columnName withValue:(NSString *)newValue inTable:(NSString *)tableName {
    if (recordIDs.count == 0 || !columnName || !newValue || !tableName) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = '%@' WHERE id IN (%@);", tableName, columnName, newValue, [recordIDs componentsJoinedByString:@","]];
    return [self execUpdateSQL:sql];
}

- (BOOL)execUpdateSQL:(NSString *)sql {
    if (![self databaseCheck]) {
        return NO;
    }

    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        HNLogError(@"Prepare update records query failure: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        HNLogError(@"Failed to update records from database, error: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    sqlite3_finalize(stmt);
    return YES;
}

- (NSUInteger)recordCountWithStatus:(HNEventRecordStatus)status {
    if (status == HNEventRecordStatusFlush) {
        return self.flushRecordCount;
    }
    return self.count - self.flushRecordCount;
}

- (BOOL)insertRecords:(NSArray<HNEventRecord *> *)records {
    if (records.count == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    if (![self preCheckForInsertRecords:records.count]) {
        return NO;
    }
    if (sqlite3_exec(_database, "BEGIN TRANSACTION", 0, 0, 0) != SQLITE_OK) {
        return NO;
    }

    NSString *query = [NSString stringWithFormat:@"INSERT INTO dataCache(type, content, %@) values(?, ?, ?)", kHNDatabaseColumnIsInstantEvent];
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    if (!insertStatement) {
        return NO;
    }
    BOOL success = YES;
    for (HNEventRecord *record in records) {
        if (![record isValid]) {
            success = NO;
            break;
        }
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 3, record.isInstantEvent ? 1 : 0);
        if (sqlite3_step(insertStatement) != SQLITE_DONE) {
            success = NO;
            break;
        }
        sqlite3_reset(insertStatement);
    }
    BOOL bulkInsertResult = sqlite3_exec(_database, success ? "COMMIT" : "ROLLBACK", 0, 0, 0) == SQLITE_OK;
    self.count = [self messagesCount];
    return bulkInsertResult;
}

- (BOOL)insertRecord:(HNEventRecord *)record {
    if (![record isValid]) {
        HNLogError(@"%@ input parameter is invalid for addObjectToDatabase", self);
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }

    if (![self preCheckForInsertRecords:1]) {
        return NO;
    }

    NSString *query = [NSString stringWithFormat:@"INSERT INTO dataCache(type, content, %@) values(?, ?, ?)", kHNDatabaseColumnIsInstantEvent];
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    int rc;
    if (insertStatement) {
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 3, record.isInstantEvent ? 1 : 0);
        rc = sqlite3_step(insertStatement);
        if (rc != SQLITE_DONE) {
            HNLogError(@"insert into dataCache table of sqlite fail, rc is %d", rc);
            return NO;
        }
        self.count++;
        HNLogDebug(@"insert into dataCache table of sqlite success, current count is %lu", self.count);
        return YES;
    } else {
        HNLogError(@"insert into dataCache table of sqlite error");
        return NO;
    }
}

- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs {
    if ((self.count == 0) || (recordIDs.count == 0)) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *query = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (%@);", [recordIDs componentsJoinedByString:@","]];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        HNLogError(@"Prepare delete records query failure: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    BOOL success = YES;
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        HNLogError(@"Failed to delete record from database, error: %s", sqlite3_errmsg(_database));
        success = NO;
    }
    sqlite3_finalize(stmt);
    self.count = [self messagesCount];
    self.flushRecordCount -= recordIDs.count;
    return success;
}

- (BOOL)deleteFirstRecords:(NSUInteger)recordSize {
    if (self.count == 0 || recordSize == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSUInteger removeSize = MIN(recordSize, self.count);
    NSString *query = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (SELECT id FROM dataCache ORDER BY id ASC LIMIT %lu);", (unsigned long)removeSize];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        HNLogError(@"Prepare delete records query failure: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        HNLogError(@"Failed to delete record from database, error: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        self.count = [self messagesCount];
        return NO;
    }
    sqlite3_finalize(stmt);
    self.count = self.count - removeSize;
    return YES;
}

- (BOOL)deleteAllRecords {
    if (self.count == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *sql = @"DELETE FROM dataCache";
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        HNLogError(@"Failed to delete all records");
        return NO;
    } else {
        HNLogDebug(@"Delete all records successfully");
    }
    self.count = 0;
    return YES;
}

- (BOOL)preCheckForInsertRecords:(NSUInteger)recordSize {
    if (recordSize > self.maxCacheSize) {
        return NO;
    }
    while ((self.count + recordSize) >= self.maxCacheSize) {
        HNLogWarn(@"AddObjectToDatabase touch MAX_MESHNGE_SIZE:%lu, try to delete some old events", self.maxCacheSize);
        if (![self deleteFirstRecords:kRemoveFirstRecordsDefaultCount]) {
            HNLogError(@"AddObjectToDatabase touch MAX_MESHNGE_SIZE:%lu, try to delete some old events FAILED", self.maxCacheSize);
            return NO;
        }
    }
    return YES;
}

- (void)createStmtCache {
    CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
    CFDictionaryValueCallBacks valueCallbacks = { 0 };
    _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
}

- (sqlite3_stmt *)dbCacheStmt:(NSString *)sql {
    if (sql.length == 0 || !_dbStmtCache) return NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if (!stmt) {
        int result = sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            HNLogError(@"sqlite stmt prepare error (%d): %s", result, sqlite3_errmsg(_database));
            sqlite3_finalize(stmt);
            return NULL;
        }
        CFDictionarySetValue(_dbStmtCache, (__bridge const void *)(sql), stmt);
    } else {
        sqlite3_reset(stmt);
    }
    return stmt;
}

- (BOOL)columnExists:(NSString *)columnName inTable:(NSString *)tableName {
    if (!columnName) {
        return NO;
    }
    return [[self columnsInTable:tableName] containsObject:columnName];
}

- (NSArray<NSString *>*)columnsInTable:(NSString *)tableName {
    NSMutableArray<NSString *> *columns = [NSMutableArray array];
    NSString *query = [NSString stringWithFormat: @"PRAGMA table_info('%@');", tableName];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        HNLogError(@"Prepare PRAGMA table_info query failure: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return columns;
    }

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        char *name = (char *)sqlite3_column_text(stmt, 1);
        if (!name) {
            continue;
        }
        NSString *column = [NSString stringWithUTF8String:name];
        if (column) {
            [columns addObject:column];
        }
    }
    sqlite3_finalize(stmt);
    return columns;
}

//默认添加一个整型的默认值为 0 的一列
- (BOOL)createColumn:(NSString *)columnName inTable:(NSString *)tableName {
    if ([self columnExists:columnName inTable:tableName]) {
        return YES;
    }

    NSString *query = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ INTEGER NOT NULL DEFAULT (0);", tableName, columnName];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        HNLogError(@"Prepare create column query failure: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        HNLogError(@"Failed to create column, error: %s", sqlite3_errmsg(_database));
        sqlite3_finalize(stmt);
        return NO;
    }
    sqlite3_finalize(stmt);
    return YES;
}

//MARK: execute sql statement to get total event records count stored in database
- (NSUInteger)messagesCount {
    NSString *query = @"select count(*) from dataCache";
    int count = 0;
    sqlite3_stmt *statement = [self dbCacheStmt:query];
    if (statement) {
        while (sqlite3_step(statement) == SQLITE_ROW)
            count = sqlite3_column_int(statement, 0);
    } else {
        HNLogError(@"Failed to get count form dataCache");
    }
    return (NSUInteger)count;
}

- (void)dealloc {
    [self close];
}

@end
