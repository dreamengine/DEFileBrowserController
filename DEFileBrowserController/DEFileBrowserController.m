//
//  DEFileBrowserController.m
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

#import "DEFileBrowserController.h"

#import "DEFileBrowserDefaultCell.h"


static NSString * const kDEFileBrowserController_ReuseIdentifier = @"kDEFileBrowserController_ReuseIdentifier";

typedef enum DEFileBrowserCreationState {
    DEFileBrowserCreationStateNone,
    DEFileBrowserCreationStateFileCreation,
    DEFileBrowserCreationStateFileAlreadyExists,
    DEFileBrowserCreationStateConfirmFileOverwrite,
    DEFileBrowserCreationStateFolderCreation,
    DEFileBrowserCreationStateFolderAlreadyExists,
} DEFileBrowserCreationState;


@interface DEFileBrowserController ()

@property (strong, nonatomic) DEFileBrowserController *subfolderController;

//@property (strong, nonatomic) UITableView *tableView;

@property (readonly, nonatomic) NSString *applicationDocumentsDirectory;

@property (strong, nonatomic) NSArray *folderPaths;
@property (strong, nonatomic) NSArray *filePaths;

@property (copy, nonatomic) NSString *pendingOverwriteFilePath;

@property (nonatomic) DEFileBrowserCreationState creationState;


-(void) de_setup;

-(void) configureCell: (UITableViewCell<DEFileBrowserControllerCell> *)cell
          atIndexPath: (NSIndexPath *)indexPath;

-(void)navigateToSubfolder:(NSString *)folderPath;


// optionally override these methods for custom presentation
-(void)presentCreateFileInterface;
-(void)presentFolderAlreadyExistsInterface;
-(void)presentFileAlreadyExistsInterface;
-(void)presentCreateFolderInterface;
-(void)presentConfirmFileOverwriteInterface;


// call these from your overridden methods once the user has confirmed the file/folder name
-(void)userHasProvidedCreateFileName:(NSString *)fileName;
-(void)userHasProvidedCreateFolderName:(NSString *)folderName;
-(void)userHasConfirmedFileOverwrite;
-(void)userHasCanceledCreation;

@end


@implementation DEFileBrowserController

@dynamic applicationDocumentsDirectory;

-(id)init {
    if (self=[super init]) {
        [self de_setup];
    }

    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self de_setup];
    }

    return self;
}

-(void)de_setup {
    self.folderPaths = @[];
    self.filePaths = @[];

    _creationState = DEFileBrowserCreationStateNone;

    _canDisplayFiles = YES;
    _canDisplayFolders = YES;

    _canSelectFiles = YES;
    _canSelectFolders = NO;

    _canCreateFiles = NO;
    _canCreateFolders = NO;

    _canOverwriteFiles = NO;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    // DEFileBrowserController relies on the UINavigationBar to traverse the folder hierarchy and to provide buttons for initiating file and folder creation.
    self.navigationController.navigationBarHidden = NO;

    self.title = [self.rootFolderPath lastPathComponent];

    [self.tableView registerClass: self.tableCellClass
           forCellReuseIdentifier: kDEFileBrowserController_ReuseIdentifier];

    [self refreshFolderListings];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSMutableArray *rightItems = [NSMutableArray arrayWithCapacity:2];
    if (self.canCreateFiles) {
        [rightItems addObject:self.createFileItem];
    }
    if (self.canCreateFolders) {
        [rightItems addObject:self.createFolderItem];
    }

    self.navigationItem.rightBarButtonItems = rightItems;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath: selectedIndexPath
                                      animated: YES];
    }
}


#pragma mark - Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rowCount;
    switch (section) {
        case 0:
            rowCount = self.folderPaths.count;
            break;
        case 1:
            rowCount = self.filePaths.count;
            break;
        default:
            rowCount = 0;
            break;
    }

    return rowCount;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.tableCellClass cellHeight];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell<DEFileBrowserControllerCell> *cell = [tableView dequeueReusableCellWithIdentifier:kDEFileBrowserController_ReuseIdentifier];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(void) configureCell:(UITableViewCell<DEFileBrowserControllerCell> *)cell
          atIndexPath: (NSIndexPath *)indexPath {
    NSString *itemPath;
    if (indexPath.section == 0) {
        itemPath = self.folderPaths[indexPath.row];
        [cell configureCellForFolder: itemPath
                      inParentFolder: self.rootFolderPath
            forFileBrowserController: self];

        cell.userInteractionEnabled = YES;
    }
    else {
        itemPath = self.filePaths[indexPath.row];
        [cell configureCellForFile: itemPath
                    inParentFolder: self.rootFolderPath
          forFileBrowserController: self];

        if (self.canSelectFiles) {
            cell.userInteractionEnabled = YES;
        }
        else {
            cell.userInteractionEnabled = NO;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *itemPath;

    if (indexPath.section == 0) {
        itemPath = self.folderPaths[indexPath.row];
        [self folderSelected:itemPath];
    }
    else {
        itemPath = self.filePaths[indexPath.row];
        [self fileSelected:itemPath];
    }
}

- (void)tableView: (UITableView *)tableView
  willDisplayCell: (UITableViewCell *)cell
forRowAtIndexPath: (NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.canSelectFolders) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 &&
        indexPath.row < self.folderPaths.count &&
        self.canSelectFolders) {
        NSString *folderPath = self.folderPaths[indexPath.row];
        [self navigateToSubfolder:folderPath];
    }
}


#pragma mark - Item Selection

-(void)folderSelected:(NSString *)folderPath {
    if (self.canSelectFolders) {
        if (self.folderSelectedBlock) {
            NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:folderPath];
            self.folderSelectedBlock(fullPath);
        }
    }
    else {
        [self navigateToSubfolder:folderPath];
    }
}

-(void)fileSelected:(NSString *)filePath {
    if (self.canSelectFiles && self.fileSelectedBlock) {
        NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:filePath];
        self.fileSelectedBlock(fullPath);
    }
}


#pragma mark - Refresh Folder Listings

-(void)refreshFolderListings {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contentList = [manager contentsOfDirectoryAtPath:self.rootFolderPath error:nil];

    NSMutableArray *folderPaths = [NSMutableArray array];
    NSMutableArray *filePaths = [NSMutableArray array];

    for (NSString *contentItem in contentList) {
        // Don't list system files/folders, e.g. .DS_Store
        if ([contentItem hasPrefix:@"."] ||
            [contentItem isEqualToString:@"__MACOSX"]) {
            continue;
        }

        NSError *error = nil;
        NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:contentItem];
        NSDictionary *itemAttributes = [manager attributesOfItemAtPath: fullPath
                                                                 error: &error];

        if (error || !itemAttributes) {
            continue;
        }

        NSString *itemType = itemAttributes[NSFileType];
        if (!itemType) {
            continue;
        }

        if ([itemType isEqualToString:NSFileTypeDirectory]) {
            if (self.canDisplayFolders) {
                [folderPaths addObject:contentItem];
            }
        }
        else if ([itemType isEqualToString:NSFileTypeRegular]) {
            if (self.canDisplayFiles) {
                [filePaths addObject:contentItem];
            }
        }
    }

    self.folderPaths = [NSArray arrayWithArray:folderPaths];
    self.filePaths = [NSArray arrayWithArray:filePaths];

    [self.tableView reloadData];
}


#pragma mark - Navigation

-(void)navigateToSubfolder:(NSString *)folderPath {
    DEFileBrowserController *subfolderController = [[self class] new];
    self.subfolderController = subfolderController;

    NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:folderPath];
    self.subfolderController.rootFolderPath = fullPath;
    self.subfolderController.tableCellClass = self.tableCellClass;

    self.subfolderController.canDisplayFiles = self.canDisplayFiles;
    self.subfolderController.canDisplayFolders = self.canDisplayFolders;
    self.subfolderController.canSelectFiles = self.canSelectFiles;
    self.subfolderController.canSelectFolders = self.canSelectFolders;

    self.subfolderController.canCreateFiles = self.canCreateFiles;
    self.subfolderController.fileCreationExtension = self.fileCreationExtension;
    self.subfolderController.canCreateFolders = self.canCreateFolders;

    self.subfolderController.fileSelectedBlock = self.fileSelectedBlock;
    self.subfolderController.folderSelectedBlock = self.folderSelectedBlock;
    self.subfolderController.fileShouldBeCreatedBlock = self.fileShouldBeCreatedBlock;
    self.subfolderController.folderCreatedBlock = self.folderCreatedBlock;

    self.subfolderController.canOverwriteFiles = self.canOverwriteFiles;

    [self.navigationController pushViewController: subfolderController
                                         animated: YES];
}


#pragma mark - File/Folder Creation Finite State Machine

// simple finite state machine for creation state
-(void)setCreationState:(DEFileBrowserCreationState)creationState {
    if (_creationState != creationState) {
        _creationState = creationState;
        
        switch (_creationState) {
            case DEFileBrowserCreationStateFileCreation:
                [self presentCreateFileInterface];
                break;
            case DEFileBrowserCreationStateFolderCreation:
                [self presentCreateFolderInterface];
                break;
            case DEFileBrowserCreationStateFileAlreadyExists:
                [self presentFileAlreadyExistsInterface];
                break;
            case DEFileBrowserCreationStateFolderAlreadyExists:
                [self presentFolderAlreadyExistsInterface];
                break;
            case DEFileBrowserCreationStateConfirmFileOverwrite:
                [self presentConfirmFileOverwriteInterface];
                break;
            case DEFileBrowserCreationStateNone:
                break;
            default:
                break;
        }
    }
}


#pragma mark - File/Folder Creation Interface

-(void)createFileItemTapped {
    self.creationState = DEFileBrowserCreationStateFileCreation;
}

-(void)createFolderItemTapped {
    self.creationState = DEFileBrowserCreationStateFolderCreation;
}

// override to provide a custom file creation interface
-(void)presentCreateFileInterface {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Create New File"
                                                        message: @""
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles: @"Create File", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Enter File Name";
    
    self.creationState = DEFileBrowserCreationStateFileCreation;
    
    [alertView show];
}

// override to provide a custom file creation interface
-(void)presentFolderAlreadyExistsInterface {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Create New Folder"
                                                        message: @"Folder Already Exists. Please Try Again."
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles: @"Create Folder", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Enter Folder Name";
    
    self.creationState = DEFileBrowserCreationStateFolderCreation;
    
    [alertView show];
}

// override to provide a custom file creation interface
-(void)presentFileAlreadyExistsInterface {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Create New File"
                                                        message: @"File Already Exists. Please Try Again."
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles: @"Create File", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Enter File Name";
    
    self.creationState = DEFileBrowserCreationStateFileCreation;
    
    [alertView show];
}

// override to provide a custom file creation interface
-(void)presentCreateFolderInterface {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Create New Folder"
                                                        message: @""
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles: @"Create Folder", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Enter Folder Name";

    self.creationState = DEFileBrowserCreationStateFolderCreation;
    
    [alertView show];
}

// override to provide a custom file creation interface
-(void)presentConfirmFileOverwriteInterface {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Confirm File Overwrite"
                                                        message: @"File already exists. Do you want to overwrite it?"
                                                       delegate: self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles: @"Overwrite File", nil];
    
    self.creationState = DEFileBrowserCreationStateConfirmFileOverwrite;
    
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        switch (self.creationState) {
            case DEFileBrowserCreationStateFolderCreation:
            case DEFileBrowserCreationStateFolderAlreadyExists: {
                NSString *folderName = [alertView textFieldAtIndex:0].text;
                [self userHasProvidedCreateFolderName:folderName];
            }
                break;
            case DEFileBrowserCreationStateConfirmFileOverwrite: {
                [self userHasConfirmedFileOverwrite];
            }
                break;
            case DEFileBrowserCreationStateFileCreation: {
                NSString *fileName = [alertView textFieldAtIndex:0].text;
                [self userHasProvidedCreateFileName:fileName];
            }
                break;
            default:
                break;
        }
    }
    else {
        [self userHasCanceledCreation];
    }
}


#pragma mark - Handle File/Folder Creation User Input

// call this from your subclass once the user has confirmed the file name
-(void)userHasProvidedCreateFileName:(NSString *)fileName {
    NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:fileName];
    
    if (self.fileCreationExtension) {
        fullPath = [fullPath stringByAppendingPathExtension:self.fileCreationExtension];
    }
    
    if ([self fileExistsAtAbsolutePath:fullPath]) {
        if (self.canOverwriteFiles) {
            self.pendingOverwriteFilePath = fullPath;
            self.creationState = DEFileBrowserCreationStateConfirmFileOverwrite;
        }
        else {
            self.creationState = DEFileBrowserCreationStateFileAlreadyExists;
        }
    }
    else {
        if (self.fileShouldBeCreatedBlock) {
            self.fileShouldBeCreatedBlock(fullPath);
            self.creationState = DEFileBrowserCreationStateNone;
        }
    }
}

// call this from your subclass once the user has confirmed the file name
-(void)userHasProvidedCreateFolderName:(NSString *)folderName {
    NSString *fullPath = [self.rootFolderPath stringByAppendingPathComponent:folderName];
    
    if ([self folderExistsAtAbsolutePath:fullPath]) {
        [self presentFolderAlreadyExistsInterface];
    }
    else {
        NSError *error = [self createFolderWithAbsolutePath:fullPath];
        [self refreshFolderListings];
        if (self.folderCreatedBlock) {
            self.folderCreatedBlock(fullPath, error);
        }
    }
    
}

// call this from your subclass once the user has confirmed the overwrite
-(void)userHasConfirmedFileOverwrite {
    if (self.fileShouldBeCreatedBlock) {
        self.fileShouldBeCreatedBlock(self.pendingOverwriteFilePath);
    }
    
    self.creationState = DEFileBrowserCreationStateNone;
    
    self.pendingOverwriteFilePath = nil;
}

// call this from your subclass once the user wants to opt out of creating a file/folder
-(void)userHasCanceledCreation {
    self.creationState = DEFileBrowserCreationStateNone;
}



-(NSError *)createFolderWithAbsolutePath: (NSString *)fullPath {
    NSError *error = nil;
    
    [[NSFileManager defaultManager] createDirectoryAtPath: fullPath
                              withIntermediateDirectories: NO
                                               attributes: nil
                                                    error: &error];

    return error;
}

-(BOOL)fileExistsAtAbsolutePath:(NSString*)filename {
    BOOL isFolder;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isFolder];
    
    return fileExistsAtPath && !isFolder;
}

-(BOOL)folderExistsAtAbsolutePath:(NSString*)filename {
    BOOL isFolder;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isFolder];
    
    return fileExistsAtPath && isFolder;
}


#pragma mark - Getters/Setters

-(NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(NSString *)rootFolderPath {
    if (!_rootFolderPath) {
        _rootFolderPath = self.applicationDocumentsDirectory;
    }

    return _rootFolderPath;
}

-(Class<DEFileBrowserControllerCell>)tableCellClass {
    if (!_tableCellClass) {
        _tableCellClass = [DEFileBrowserDefaultCell class];
    }

    return _tableCellClass;
}

-(UIBarButtonItem *)createFileItem {
    if (!_createFileItem) {
        _createFileItem = [[UIBarButtonItem alloc] initWithTitle: @"+File"
                                                           style: UIBarButtonItemStyleBordered
                                                          target: self
                                                          action: @selector(createFileItemTapped)];
    }

    return _createFileItem;
}

-(UIBarButtonItem *)createFolderItem {
    if (!_createFolderItem) {
        _createFolderItem = [[UIBarButtonItem alloc] initWithTitle: @"+Folder"
                                                             style: UIBarButtonItemStyleBordered
                                                            target: self
                                                            action: @selector(createFolderItemTapped)];
    }

    return _createFolderItem;
}


@end
