//
//  DEFileBrowserDefaultCell.m
//  DEFileBrowserController
//
//  Created by Jeremy Flores on 6/4/13.
//  Copyright (c) 2013 Dream Engine Interactive, Inc. All rights reserved.
//
//  Copyright (c) 2013 Dream Engine Interactive, Inc. ( http://dreamengineinteractive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "DEFileBrowserDefaultCell.h"

@interface DEFileBrowserDefaultCell ()

@property (strong, nonatomic) UIView *mainContainerView;
@property (strong, nonatomic) UILabel *mainLabel;

@property (strong, nonatomic) UIImageView *mainIconView;

-(void)de_setup;

@end


@implementation DEFileBrowserDefaultCell

+(CGFloat)cellHeight {
    return 40.f;
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self de_setup];
    }

    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];

    [self de_setup];
}

-(id)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        [self de_setup];
    }

    return self;
}

-(void)de_setup {
    self.mainContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                      0,
                                                                      self.frame.size.width,
                                                                      self.frame.size.height)];
    [self.contentView addSubview:self.mainContainerView];
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(40,
                                                               5,
                                                               self.frame.size.width-80,
                                                               30.f)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.mainLabel.backgroundColor = [UIColor clearColor];
    [self.mainContainerView addSubview:self.mainLabel];
    
    self.mainIconView = [[UIImageView alloc] initWithFrame:CGRectMake(5,
                                                                      5,
                                                                      30,
                                                                      30)];
    self.mainIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.mainContainerView addSubview:self.mainIconView];
    
    self.cellBackgroundColor = [UIColor whiteColor];
}

#pragma mark - Getters/Setters

-(void)setCellBackgroundColor:(UIColor *)cellBackgroundColor {
    _cellBackgroundColor = cellBackgroundColor;

    self.mainContainerView.backgroundColor = _cellBackgroundColor;
}

#pragma mark - Protocol Methods

-(void)configureCellForFile: (NSString *)fileName
             inParentFolder: (NSString *)parentFolderPath
   forFileBrowserController: (DEFileBrowserController *)fileBrowserController {
    self.mainIconView.image = [UIImage imageNamed:@"de_file_browser_file_icon.png"];
    self.mainLabel.text = fileName;
}

-(void)configureCellForFolder: (NSString *)folderName
               inParentFolder: (NSString *)parentFolderPath
     forFileBrowserController: (DEFileBrowserController *)fileBrowserController {
    self.mainIconView.image = [UIImage imageNamed:@"de_file_browser_folder_icon.png"];
    self.mainLabel.text = folderName;
    self.accessoryType = UITableViewCellAccessoryCheckmark;
}

@end
