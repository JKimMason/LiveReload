@import LRCommons;
@import PackageManagerKit;

#import "ScriptInvocationStep.h"
#import "LROperationResult.h"
#import "LRActionKit-Swift.h"
#import "ActionKitSingleton.h"


@implementation ScriptInvocationStep {
    NSMutableDictionary *_substitutions;
    NSMutableDictionary *_files;
    NSMutableDictionary *_environment;
}

- (id)init {
    self = [super init];
    if (self) {
        _substitutions = [NSMutableDictionary new];
        _files = [NSMutableDictionary new];
        _environment = [[NSProcessInfo processInfo].environment mutableCopy];

        [self addValue:[[NSBundle mainBundle] pathForResource:@"LiveReloadNodejs" ofType:nil] forSubstitutionKey:@"node"];
    }
    return self;
}

- (ProjectFile *)fileForKey:(NSString *)key {
    return _files[key];
}

- (void)addValue:(id)value forSubstitutionKey:(NSString *)key {
    _substitutions[[NSString stringWithFormat:@"$(%@)", key]] = value;
}

- (void)addFileValue:(ProjectFile *)file forSubstitutionKey:(NSString *)key {
    _files[key] = file;
    [self addValue:[file.relativePath lastPathComponent] forSubstitutionKey:[NSString stringWithFormat:@"%@_file", key]];
    [self addValue:file.absolutePath forSubstitutionKey:[NSString stringWithFormat:@"%@_path", key]];
    [self addValue:[file.absolutePath stringByDeletingLastPathComponent] forSubstitutionKey:[NSString stringWithFormat:@"%@_dir", key]];
    [self addValue:file.relativePath forSubstitutionKey:[NSString stringWithFormat:@"%@_rel_path", key]];
}

- (void)invoke {
    NSArray *bundledContainers = [[[ActionKitSingleton sharedActionKit].packageManager packageTypeNamed:@"gem"].containers filteredArrayUsingBlock:^BOOL(LRPackageContainer *container) {
        return container.containerType == LRPackageContainerTypeBundled;
    }];

    RuntimeInstance *rubyInstance = _project.rubyInstanceForBuilding;
    [self addValue:[rubyInstance launchArgumentsWithAdditionalRuntimeContainers:bundledContainers environment:_environment] forSubstitutionKey:@"ruby"];

    NSArray *cmdline = [_commandLine p2_arrayBySubstitutingValuesFromDictionary:_substitutions];

    //    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    //    [[NSFileManager defaultManager] changeCurrentDirectoryPath:projectPath];

    // TODO XXX
//    console_printf("Exec: %s", str_collapse_paths([[cmdline quotedArgumentStringUsingBourneQuotingStyle] UTF8String], [_project.path UTF8String]));
    // TODO XXX: collapse project path
    NSLog(@"Exec: %@", [cmdline p2_quotedArgumentStringUsingBourneQuotingStyle]);

    NSString *command = cmdline[0];
    NSArray *args = [cmdline subarrayWithRange:NSMakeRange(1, cmdline.count - 1)];
    NSMutableDictionary *options = [@{ATCurrentDirectoryPathKey: _project.path, ATEnvironmentVariablesKey: _environment} mutableCopy];
    if (_outputLineBlock) {
        options[ATStandardOutputLineBlockKey] = _outputLineBlock;
    }
    ATLaunchUnixTaskAndCaptureOutput([NSURL fileURLWithPath:command], args, ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, options, ^(NSString *outputText, NSString *stderrText, NSError *error) {
        _error = error;
        P2DisableARCRetainCyclesWarning()
        [_result addRawOutput:outputText withCompletionBlock:^{
            [_result completedWithInvocationError:error];
            self.finished = YES;
            if (self.completionHandler)
                self.completionHandler(self);
        }];
        P2ReenableWarning()
    });
}

@end
