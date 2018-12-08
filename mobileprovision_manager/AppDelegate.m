#import "AppDelegate.h"
#import "CommonUtil.h"
#import "JSON.h"
#define get_sp(a) [[NSUserDefaults standardUserDefaults] objectForKey:a]
#define set_sp(a,b) [[NSUserDefaults standardUserDefaults] setObject:b forKey:a]
#define sp [NSUserDefaults standardUserDefaults]

#define ROOT_PATH [@"~/Library/MobileDevice/Provisioning Profiles" stringByExpandingTildeInPath]
@interface AppDelegate ()<NSTableViewDelegate,NSTableViewDataSource>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tv;
@property (strong) NSMutableArray *files;
@property (strong) NSMutableDictionary *infos;
@property (assign) BOOL flag;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.infos = [get_sp(@"infos") JSONValue];
    if(nil == self.infos){
        self.infos = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    [self reload];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

-(void) reload{
    self.files = [NSMutableArray arrayWithCapacity:5];
    NSArray *temps = [[NSFileManager defaultManager] subpathsAtPath:ROOT_PATH];
    for(NSString *each in temps){
        if([each rangeOfString:@".mobileprovision"].location != NSNotFound){
            [self.files addObject:each];
        }
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *filesCopy = [self.files mutableCopy];
        for(NSString *each in filesCopy){
            if (nil == self.infos[each]) {
                NSString *result = [self getInfoCommand:[NSString stringWithFormat:@"%@/%@",ROOT_PATH,each]];
                NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                NSString *tempParseFile = [NSString stringWithFormat:@"%@/temp.parse",ROOT_PATH];
                [data writeToFile:tempParseFile atomically:YES];
                NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:tempParseFile];
                self.infos[each] = info;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tv reloadData];
                });
            }
        }
        set_sp(@"infos", [self.infos JSONRepresentation]);
        [sp synchronize];
    });
    [self reloadWithSort];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.files.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *fileName = self.files[row];
    if ([tableColumn.identifier isEqualToString:@"1"]) {
//        NSLog(@"---%@",fileName);
        return fileName;
    }
    NSDictionary *data = self.infos[fileName];
    if (data) {
        if ([tableColumn.identifier isEqualToString:@"2"]) {
            return data[@"Name"];
        }
        if ([tableColumn.identifier isEqualToString:@"3"]) {
            return [self idd4:data];
        }
        NSDate *date = data[@"ExpirationDate"];
        if ([tableColumn.identifier isEqualToString:@"4"]) {            
            return [CommonUtil stringFromDate:date toFormat:YYYYMMDDHHMM];
        }
        if ([tableColumn.identifier isEqualToString:@"5"]) {
            
            return date.timeIntervalSinceNow  > 0 ? @"NO" : @"YES";
        }
    }
    return @"-";
}


-(NSString *) idd4:(NSDictionary *) data{
    NSString *idd = data[@"Entitlements"][@"application-identifier"];
    NSString *firstPart = [idd componentsSeparatedByString:@"."].firstObject;
    if (firstPart) {
        idd = [idd substringFromIndex:firstPart.length + 1];
    }
    return idd;
}

-(NSString *) getInfoCommand:(NSString *) path{
    NSTask *server = [NSTask new];
    [server setLaunchPath:@"/bin/sh"];
    NSString *arg = [NSString stringWithFormat:@"/usr/bin/security cms -D -i '%@'",path];
    [server setArguments:@[@"-c",arg]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [server setStandardInput:[NSPipe pipe]];
    [server setStandardOutput:outputPipe];    
    [server launch];
    [server waitUntilExit];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    return outputString;
}

-(IBAction) reloadTap:(id) sender{
    [self reload];
    [self.tv deselectAll:nil];
}

-(IBAction) deleteTap:(id) sender{
    NSIndexSet *set = self.tv.selectedRowIndexes;
    NSMutableArray *needRemoves = [NSMutableArray arrayWithCapacity:5];
    [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [needRemoves addObject:self.files[idx]];
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",ROOT_PATH, self.files[idx]]];
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }];
    [self reloadTap:nil];    
}

-(IBAction) revealTap:(id) sender{
    NSIndexSet *set = self.tv.selectedRowIndexes;
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:5];
    [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",ROOT_PATH, self.files[idx]]];
        if(nil == url){
            NSLog(@"error with %@",self.files[idx]);
        }else{
            [urls addObject:url];
        }
    }];
    
    if (urls.count == 0) {
        return;
    }
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}


-(void) reloadWithSort{
    NSSortDescriptor *sd = self.tv.sortDescriptors.firstObject;
    NSLog(@"sd. [%@]",sd.key);
    if (sd) {
        if([sd.key isEqualToString:@"1"]){
            [self.files sortUsingComparator:^NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
                if (sd.ascending) {
                    return [obj1 compare:obj2];
                }else{
                    return [obj2 compare:obj1];
                }
            }];
        }
        [self.files sortUsingComparator:^NSComparisonResult(NSString *_Nonnull fileName1, NSString *_Nonnull fileName2) {
            NSDictionary *obj1 = self.infos[fileName1];
            NSDictionary *obj2 = self.infos[fileName2];
            if (obj1 == nil && obj2 == nil) {
                return NSOrderedSame;
            }
            if (sd.ascending) {
                if (obj1 == nil) {
                    return NSOrderedAscending;
                }
                if (obj2 == nil) {
                    return NSOrderedDescending;
                }
                if([sd.key isEqualToString:@"2"]){
                    NSString *name1 = obj1[@"Name"];
                    NSString *name2 = obj2[@"Name"];
                    return [name1 compare:name2];
                }
                if([sd.key isEqualToString:@"3"]){
                    NSString *name1 = [self idd4:obj1];
                    NSString *name2 = [self idd4:obj2];
                    return [name1 compare:name2];
                }
                if([sd.key isEqualToString:@"4"] || [sd.key isEqualToString:@"5"]){
                    NSDate *date1 = obj1[@"ExpirationDate"];
                    NSDate *date2 = obj2[@"ExpirationDate"];
                    return [date1 compare:date2];
                }
                return NSOrderedAscending;
            }else{
                if (obj1 == nil) {
                    return NSOrderedDescending;
                }
                if (obj2 == nil) {
                    return NSOrderedAscending;
                }
                if([sd.key isEqualToString:@"2"]){
                    NSString *name1 = obj1[@"Name"];
                    NSString *name2 = obj2[@"Name"];
                    return [name2 compare:name1];
                }
                if([sd.key isEqualToString:@"3"]){
                    NSString *name1 = [self idd4:obj1];
                    NSString *name2 = [self idd4:obj2];
                    return [name2 compare:name1];
                }
                if([sd.key isEqualToString:@"4"] || [sd.key isEqualToString:@"5"]){
                    NSDate *date1 = obj1[@"ExpirationDate"];
                    NSDate *date2 = obj2[@"ExpirationDate"];
                    return [date2 compare:date1];
                }
                return NSOrderedAscending;
            }
        }];
        
    }
    [self.tv reloadData];
}
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors{
    [self reloadWithSort];
}

@end
