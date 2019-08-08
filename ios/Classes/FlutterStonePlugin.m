#import "FlutterStonePlugin.h"
#import <flutter_stone/flutter_stone-Swift.h>

@implementation FlutterStonePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterStonePlugin registerWithRegistrar:registrar];
}
@end
