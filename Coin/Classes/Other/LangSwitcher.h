//
//  LangSwitcher.h
//  Coin
//
//  Created by  tianlei on 2017/12/08.
//  Copyright © 2017年  tianlei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LangSwitcher : NSObject


/**
 key 传nil
 */
+ (NSString *)switchLang:(NSString *)content key:(NSString *)key;

@end
