//
//  QPlayAutoEntity.m
//  QQMusic
//
//  Created by lijuyou on 15-2-10.
//
//

#import "QPlayAutoEntity.h"
#import "QMMacros.h"


NSString *const kQPlayAutoArgument_Count = @"Count";
NSString *const kQPlayAutoArgument_PageIndex = @"PageIndex";
NSString *const kQPlayAutoArgument_ParentID = @"ParentID";
NSString *const kQPlayAutoArgument_Lists = @"Lists";
NSString *const kQPlayAutoArgument_PlayMode = @"PlayMode";
NSString *const kQPlayAutoArgument_IsFav = @"isFav";
NSString *const kQPlayAutoArgument_Position = @"Position";
NSString *const kQPlayAutoArgument_Song = @"Song";
NSString *const kQPlayAutoArgument_SongID = @"SongID";
NSString *const kQPlayAutoArgument_State = @"State";
//NSString *const kQPlayAutoArgument_ = @"";


@implementation QPlayAutoListItem

- (instancetype)initWithDictionary:(NSDictionary*)dict
{
    if(self = [super init])
    {
        self.ID =  [dict objectForKey:@"ID"];
        self.Name =  [dict objectForKey:@"Name"];
        self.Artist =  [dict objectForKey:@"Artist"];
        self.Album =  [dict objectForKey:@"Album"];
        self.Type = (QPlayAutoListItemType)[[dict objectForKey:@"Type"] integerValue];
        self.Duration = [[dict objectForKey:@"Duration"] integerValue];
        self.CoverUri = [dict objectForKey:@"CoverUri"];
        self.Mid = [dict objectForKey:@"Mid"];
    }
    return self;
}

- (BOOL)isRoot
{
    return self.Type == QPlayAutoListItemType_Normal && [self.ID isEqualToString:kQPlayAutoItemRootID];
}

- (BOOL)hasMore
{
    return self.totalCount==-1
    || (self.totalCount>0 && self.items.count < self.totalCount);
}

- (QPlayAutoListItem*)findItemWithID:(NSString*)ID
{
    if ([self.ID isEqualToString:ID])
        return self;
    for(QPlayAutoListItem *item in self.items)
    {
        QPlayAutoListItem *target = [item findItemWithID:ID];
        if(target)
        {
            return target;
        }
    }
    return nil;
}

@end

@implementation QPlayAutoMediaInfo

- (instancetype)initWithDictionary:(NSDictionary*)dict
{
    if(self = [super init])
    {
        self.songID = [dict objectForKey:@"SongID"];
        self.pcmDataLength = [[dict objectForKey:@"PCMDataLength"] integerValue];
        self.rate = [[dict objectForKey:@"Rate"] integerValue];
        self.bit = [[dict objectForKey:@"Bit"] integerValue];
        self.channel = [[dict objectForKey:@"Channel"] integerValue];
        
    }
    return self;
}
@end

@implementation QPlayAutoAppInfo
@end

@implementation QPlayAutoPlayInfo

- (instancetype)initWithDictionary:(NSDictionary*)dict
{
    if(self = [super init])
    {
        self.songID = [dict objectForKey:@"SongID"];
        self.name =  [dict objectForKey:@"Name"];
        self.artist =  [dict objectForKey:@"Artist"];
        self.album =  [dict objectForKey:@"Album"];
        self.duration = [[dict objectForKey:@"Duration"] integerValue];
        self.playState = [[dict objectForKey:@"PlayState"] integerValue];
        self.isFav = [[dict objectForKey:@"isFav"] boolValue];
    }
    return self;
}

@end

@interface QPlayAutoRequestInfo()
@property (nonatomic,strong) NSString *key;
@end

@implementation QPlayAutoRequestInfo

- (instancetype)initWithRequestNO:(NSInteger)requestNo finishBlock:(QPlayAutoRequestFinishBlock)finishBlock
{
    if(self = [super init])
    {
        self.requestNo = requestNo;
        self.finishBlock = finishBlock;
        self.key = [NSString stringWithFormat:@"%ld",(long)requestNo];
    }
    return self;
}
- (instancetype)initWithRequestKey:(NSString *)requestKey finishBlock:(QPlayAutoRequestFinishBlock)finishBlock {
    if(self = [super init])
    {
        self.requestNo = 99999999999999;
        self.finishBlock = finishBlock;
        self.key = requestKey;
    }
    return self;
}
@end
