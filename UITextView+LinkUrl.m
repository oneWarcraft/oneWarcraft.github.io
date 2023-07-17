//
//  UITextView+LinkUrl.m
//  kiosoft
//
//  Created by Wade on 2023/3/7.
//  Copyright © 2023 Ubix Innovations. All rights reserved.
//

#import "UITextView+LinkUrl.h"

@implementation UITextView (LinkUrl)
NSRange searchRange;
- (void)setTextWithLinkAttribute:(NSString *)text {

    self.attributedText = [self subStr:text];

}

-(NSMutableAttributedString*)subStr:(NSString *)string
{

    NSError *error;

    //可以识别url的正则表达式
    //([a-zA-Z]{2,4})换成(net|com||org|gov|edu|mil|info|travel|pro|museum|biz|[a-z]{2})

    NSString *regulaStr = @"(((http[s]{0,1}|ftp)://|www\\.)[a-zA-Z0-9\\.\\-]+(\\.(net|com|live|org|gov|edu|mil|info|travel|pro|museum|biz|[a-z]{2,4}))?(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|([a-zA-Z0-9\\.\\-]+\\.(net|com|live|org|gov|edu|mil|info|travel|pro|museum|biz|cn|[a-z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    
//    "((/[0-9a-z_!~*'().;?:@&=+$,%#-]+)+/?)$"
    

      
//      (((http[s]{0,1}|ftp)://|www\\.)[a-zA-Z0-9\\.\\-]+(\\.(net|com|cn|live|org|gov|edu|mil|info|travel|pro|museum|biz|[a-z]{2,4}))?(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|([a-zA-Z]+\\.(net|com|live|org|gov|edu|mil|info|travel|pro|museum|biz|cn))
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr

                                                                           options:NSRegularExpressionCaseInsensitive

                                                                             error:&error];

    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

    NSMutableArray *arr=[[NSMutableArray alloc]init];

    NSMutableArray *rangeArr=[[NSMutableArray alloc]init];



    for (NSTextCheckingResult *match in arrayOfAllMatches)

    {

        NSString* substringForMatch;

        substringForMatch = [string substringWithRange:match.range];
        substringForMatch = [substringForMatch hasSuffix:@"."] ? [substringForMatch substringToIndex:substringForMatch.length - 1] : substringForMatch;

        [arr addObject:substringForMatch];

    }

    NSString *subStr=string;
    searchRange = NSMakeRange(0, [subStr length]);

    for (NSString *str in arr) {

        [rangeArr addObject:[self rangesOfString:str inString:subStr]];

    }

    CGRect rect = [[UIScreen mainScreen] bounds];
    CGSize size = rect.size;
    CGFloat width = size.width;
    CGFloat textSize = 0.0f;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        textSize = 16 * width/375.0;
    }else{
        textSize = 16 * width/810.0;
    }
    UIFont *font = [UIFont systemFontOfSize:textSize];

    NSMutableAttributedString *attributedText;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    attributedText=[[NSMutableAttributedString alloc]initWithString:subStr attributes:@{NSFontAttributeName :font,
                                                                                        NSParagraphStyleAttributeName:paragraphStyle
                                                                                      }];



    for(NSValue *value in rangeArr)

    {

        NSInteger index=[rangeArr indexOfObject:value];

        NSRange range=[value rangeValue];

        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
        
        [attributedText addAttribute:NSLinkAttributeName value:[NSURL URLWithString:[arr objectAtIndex:index]] range:range];


    }

    return attributedText;
}

//获取查找字符串在母串中的NSRange

- (NSValue *)rangesOfString:(NSString *)searchString inString:(NSString *)str {

    NSRange range;
    if ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {

        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));

    }

    return [NSValue valueWithRange:range];
}
@end
