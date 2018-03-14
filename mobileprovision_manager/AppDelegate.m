#import "AppDelegate.h"
#import "CommonUtil.h"
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
    // Insert code here to initialize your application
    self.infos = [NSMutableDictionary dictionaryWithCapacity:5];
    [self reload];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
        for(NSString *each in self.files){
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
    });
    [self.tv reloadData];
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
            NSString *idd = data[@"Entitlements"][@"application-identifier"];
            NSString *firstPart = [idd componentsSeparatedByString:@"."].firstObject;
            if (firstPart) {
                idd = [idd substringFromIndex:firstPart.length + 1];
            }
            return idd;
        }
        if ([tableColumn.identifier isEqualToString:@"3"]) {
            NSDate *date = data[@"ExpirationDate"];
            return date.timeIntervalSinceNow  > 0 ? @"NO" : @"YES";
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

@end
