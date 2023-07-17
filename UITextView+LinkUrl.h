//
//  UITextView+LinkUrl.h
//  kiosoft
//
//  Created by Wade on 2023/3/7.
//  Copyright © 2023 Ubix Innovations. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (LinkUrl)
- (void)setTextWithLinkAttribute:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
