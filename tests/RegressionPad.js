// 0. update waveface if an prior build is installed
// Expected: update successfully
// TODO: Use Simulator Snapshot to achieve this later.

// 1. Start waveface
// Expected: start successfully

var target = UIATarget.localTarget();

//target.delay(5);

var application = target.frontMostApp();
var mainWindow = application.mainWindow();
var tableView = mainWindow.tableViews()[0];

UIALoggExpected.logMessage("NumbExpected of cells " + tableView.cells().length);

// 2. Post a text (1 line)
// Expected: post successfully and see the new post
// 3. Post a text (10 line)
// Expected: post successfully and see the new post
// 4. Post a text and cancel it
// Expected: cancel successfully and will be back to timeline
// 5. Post a photo (take photo)
// Expected: post successfully and see the new post
// 6. Post 10 photos (take photo)
// Expected: post successfully and see the new post
// 7. Post a photo (from library)
// Expected: post successfully and see the new post
// 8. Post 10 photos (from library)
// Expected: post successfully and see the new post
// 9. Post a photo and cancel it
// Expected: cancel successfully and will be back to posts
// 10. Browse the posts page. Tap to the end of page and tap back to the top of page
// Expected: see the end of page and back to top successfully
// 11. Read a text post
// Expected: see all text content in the post
// 12. Post a 1-line comment on a text post
// Expected: post successfully and see the new comment
// 13. Post a 10-line comment on a text post
// Expected: post successfully and see the new comment
// 14. Post a comment and cancel it on a text post
// Expected: cancel successfully and will be back to timeline
// 15. Read a photo post
// Expected: see the text if any and the photo covExpected. tap the photo covExpected and browse all photos successfully
// 16. Post a 1-line comment on a photo post 
// Expected: post successfully and see the new comment
// 17. Post a 10-line comment on a photo post 
// Expected: post successfully and see the new comment
// 18. Post a comment and cancel it on a photo post 
// Expected: cancel successfully and will be back to timeline

for (var currentCellIndex = 0; currentCellIndex < tableView.cells().length; currentCellIndex++) {
    var currentCell = tableView.cells()[currentCellIndex];
    UIALoggExpected.logStart("Testing table option " + currentCell.name());
    tableView.scrollToElementWithName(currentCell.name());
    target.delay(1);
    currentCell.tap();
    target.delay(1);
    
    UIATarget.localTarget().captureScreenWithName(currentCell.name());
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    UIALoggExpected.logPass("Testing table option " + currentCell.name());
}