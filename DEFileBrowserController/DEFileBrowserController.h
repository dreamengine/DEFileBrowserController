//
//  DEFileBrowserController.h
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

#import <Foundation/Foundation.h>

#import "DEFileBrowserControllerCell.h"

@class DEFileBrowserController;

typedef void (^DEFileBrowserControllerFileSelectedBlock)(NSString *selectedFilePath);

typedef void (^DEFileBrowserControllerFolderSelectedBlock)(NSString *selectedFolderPath);

typedef void (^DEFileBrowserControllerFileShouldBeCreatedBlock)(NSString *createdFilePath);

typedef void (^DEFileBrowserControllerFolderCreatedBlock)(NSString *createdFolderPath, NSError *error);



@interface DEFileBrowserController : UITableViewController

/*
 
 The root folder path from which the user is allowed to browse, e.g. the application's Documents directory.
 
 Default is the application's Documents directory.
 
 This should be set before the controller's view has been accessed, i.e. before -viewDidLoad has been called.
 
 */
@property (copy, nonatomic) NSString *rootFolderPath;

/*
 
 The custom UITableViewCell subclass to be used for custom-styled cells. The objects must adhere to the DEFileBrowserControllerCell protocol so that the file browser controller can pass relevant information on what the cell should be displaying (i.e. the file or folder path).
 
 Default is [DEFileBrowserDefaultCell class], which will take care of basic displaying.
 
 */
@property (strong, nonatomic) Class<DEFileBrowserControllerCell> tableCellClass;


/*
 
 Whether or not to display files.
 
 Default is YES.
 
 */
@property (nonatomic) BOOL canDisplayFiles;


/*
 
 Whether or not to display folders.
 
 Default is YES.
 
 */
@property (nonatomic) BOOL canDisplayFolders;

/*
 
 Whether or not the user can select files.
 
 Default is YES.
 
 If NO, then the file's cell will not have a visible accessory, and the user will not be able to tap on the cell.

 If YES, the file's cell will not have a visible accessory, and tapping anywhere on the file cell will notify the file selected block.
 
 */
@property (nonatomic) BOOL canSelectFiles;

/*
 
 Whether or not the file browser can select folders. This should only be set before the view will appear.
 
 Default is NO.
 
 If NO, then a folder's cell accessory will be a normal disclosure indicator chevron, and tapping anywhere on the folder cell will take the user to browse that folder's contents.
 
 If YES, then the folder's cell accessory will be a detail disclosure button. In this case, tapping on the detail button will take the user to browse that folder's contents. Otherwise, tapping anywhere else in the cell will select that folder and notify the folder selected block.

 */
@property (nonatomic) BOOL canSelectFolders;

/*
 
 Whether or not the user is capable of creating a new file. If YES, then a bar button item will be shown. This may be used in conjunction with canCreateFolders.
 
 Default is NO.
 
 If the user can create a new file, then DEFileBrowserController will automatically prompt the user for a filename once they have tapped the bar button item. Once the file has been created, the fileCreatedBlock will be called if it has been provided.
 
 */
@property (nonatomic) BOOL canCreateFiles;


/*
 
 Whether or not the user can overwrite already-existing files when attempting to create a file.

 Default is NO.
 
 */
@property (nonatomic) BOOL canOverwriteFiles;


/*
 
 The file extension to be used whenever the user creates a new file. If set to nil, then this will be ignored when attempting to create the file. This will only be used when canCreateFiles==YES and the user successfully creates a file.
 
 By default, this is nil.
 
 */
@property (copy, nonatomic) NSString *fileCreationExtension;

/*
 
 The bar button item to be shown when the user is allowed to create file.
 
 Default is a bar button item whose title is @"+File".
 
 A custom bar button item may be set, but only by subclassing DEFileBrowserController and internally setting the createFileItem. If a custom bar button item is set, its target must be self and its action must be @selector(createFileItemTapped).
 
 */
@property (strong, nonatomic) UIBarButtonItem *createFileItem;


/*
 
 Whether or not the user is capable of creating a new folder. If YES, then a bar button item will be shown. This may be used in conjunction with canCreateFiles.
 
 Default is NO.
 
 If the user can create a new folder, then DEFileBrowserController will automatically prompt the user for a folder name once they have tapped the bar button item. Once the folder has been created, the folderCreatedBlock will be called if it has been provided.
 
 */
@property (nonatomic) BOOL canCreateFolders;

/*
 
 The bar button item to be shown when the user is allowed to create folders.
 
 Default is a bar button item whose title is @"+Folder".

 A custom bar button item may be set, but only by subclassing DEFileBrowserController and internally setting the createFolderItem. If a custom bar button item is set, its target must be self and its action must be @selector(createFolderItemTapped).
 
 */
@property (strong, nonatomic) UIBarButtonItem *createFolderItem;


/*
 
 Executed when the user has selected a file.
 
 */
@property (copy, nonatomic) DEFileBrowserControllerFileSelectedBlock fileSelectedBlock;

/*
 
 Executed when the user has selected a folder. This will only be called when canSelectFolders==YES and if the user taps on the cell's main contents but not on the detail disclosure button.
 
 */
@property (copy, nonatomic) DEFileBrowserControllerFolderSelectedBlock folderSelectedBlock;

/*
 
 Executed when the user has successfully chosen a parent folder and provided a file name. This can only be called when canCreateFiles==YES.
 
 */
@property (copy, nonatomic) DEFileBrowserControllerFileShouldBeCreatedBlock fileShouldBeCreatedBlock;

/*
 
 Executed when the user has attempted to create a folder. This can only be called when canCreateFolders==YES.
 
 This block takes in the full path of the folder the user attempted to create as well as any error that may have occurred during the creation process. If error==nil, then the folder should have been successfully created.
 
 */
@property (copy, nonatomic) DEFileBrowserControllerFolderCreatedBlock folderCreatedBlock;


/*

 Manually updates the table to have the most up-to-date file listing. This will propagate down to the DEFileBrowserController currently on the screen. DEFileBrowserControllers will automatically refresh their listings once viewDidAppear: is called.
 
 */
-(void)refreshFolderListings;

@end
