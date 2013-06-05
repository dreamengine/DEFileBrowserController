#DEFileBrowserController


Standardized File Saving and Loading for iOS


##What It Does

`DEFileBrowserController` is an MIT-licensed library that makes file saving and loading easier. It provides a file browsing view controller system that automatically provides the user a way of navigating and doing basic manipulation of folder hierarchies.

You can also optionally provide the user an option to create subfolders or new files. When creating new files or folders, `DEFileBrowserController` will check to see if a file or folder with the same name already exists and prompts the user to enter a new name. It will also optionally provide the ability to confirm overwriting existing files with the user. Your code will only be called when a new path which is safe to create has been chosen by the user.

`DEFileBrowserController` also provides an interface for you to provide custom cells. All you have to do is create a UITableViewCell subclass that adheres to the `DEFileBrowserControllerCell` protocol. You can also use the provided `DEFileBrowserDefaultCell` class, which is the default cell used by the controllers.

`DEFileBrowserController` exposes mechanisms for customizing its behavior. For example, the default options to create files or folders are presented in title-based `UIBarButtonItems`, and entering a new file or folder name is done via `UIAlertViews`. To change either of these approaches, you can simply subclass DEFileBrowserController and follow some simple steps, and you'll be good to go.


##Example


	/*
	
	  Create a browser controller for saving a new image to a file.
	  
	  It will also allow the user to create subfolders on the fly.

	*/

	// By default, DEFileBrowserController points to the application's Documents folder, so we'll just use that and not bother setting a new root folder

	DEFileBrowserController *controller = [DEFileBrowserController new];	
	controller.canCreateFiles = YES;
	controller.canCreateFolders = YES;
	controller.canSelectFiles = NO;
	controller.canSelectFolders = NO;
	controller.canOverwriteFiles = YES;
	controller.fileCreationExtension = @"png";	// DEFileBrowserController allows you to prepopulate the file extension before your block is called.

	// the image which we're going to save
	__block UIImage *imageToSave = ...;

	// reference to self, which is a UIViewController
	__weak UIViewController *weakSelf = self;

	controller.fileShouldBeCreatedBlock =
    ^(NSString *createdFilePath) {
    	NSData *imageData = UIImagePNGRepresentation(imageToSave);

		[imageData writeToFile:createdFilePath atomically:YES];

		[weakSelf.navigationController popToViewController:weakSelf animated:YES];
    };

	[self.navigationController pushViewController:controller animated:YES];