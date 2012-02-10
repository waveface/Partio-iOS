// 0.a update waveface if an prior build is installed
// Expected: update successfully
// TODO: Use Simulator Snapshot to achieve this later.
var countTest = 1
var testName = "Regression Test " + countTest + " - update waveface";
countTest++;
UIALogger.logStart(testName);

UIALogger.logPass(testName);


// 0.b fresh install waveface
// Expected: install successfully
// TODO: Use a clean Simulator Snapshot

// 1. Start waveface
// Expected: start successfully
testName = "Regression Test " + countTest + " - start waveface";
countTest++;
UIALogger.logStart(testName);

var target = UIATarget.localTarget();
// target.logElementTree();

var application = target.frontMostApp();
var mainWindow = application.mainWindow();
var naviBar = mainWindow.navigationBar();

UIALogger.logPass(testName);



// 2. Post a text (1 line)
// Expected: post successfully and see the new post
// TODO: have a wait-till-next-item function
testName = "Regression Test " + countTest + " - post a text (1 line)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
mainWindow.logElementTree();
naviBar.elements()[3].buttons()["Compose"].tap();

var text = mainWindow.textViews()[0];
var msg = testName + " " + new Date().getTime();
text.setValue(msg);

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.navigationBars()["Compose"].buttons()[1].tap();

UIALogger.logMessage("Post 1 line text!");


// scroll right to the end
mainWindow.sliders()[0].dragToValue(1);

// Verification
// a. the checkmark image
// b. the new post in timeline
// TODO: need new post cell's attribute to verify display
if (mainWindow.elements()["WAOverlayBezel-Checkmark"].isEnabled()) {
    UIALogger.logMessage("Checkmark shows!");
}
else {
    UIALogger.logFail(testName + " - no checkmark");
}


UIALogger.logMessage(msg);
mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].logElementTree();
if (mainWindow.scrollViews()[0].elements()[msg]) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName + "- no new post in timeline");
}


// 3. Post a text (10 line)
// Expected: post successfully and see the new post

testName = "Regression Test " + countTest + " - post a text (10 line)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
naviBar.elements()[3].buttons()["Compose"].tap();

text = mainWindow.textViews()[0];
msg = "";
for (var count=1; count <= 10; count++) {msg += (testName + " " + new Date().getTime() + "\n");}
text.setValue(msg);

mainWindow.navigationBars()["Compose"].buttons()[1].tap();

UIALogger.logMessage("Post 10 line text!");

// Verification
// a. the checkmark image
// b. the new post in timeline 
target.delay(1);
if (mainWindow.elements()["WAOverlayBezel-Checkmark"].isEnabled()) {
    UIALogger.logMessage("Checkmark shows!");
}
else {
    UIALogger.logFail(testName + " - no checkmark");
}
target.delay(1);
if (mainWindow.elements()[msg]) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName + "- no new post in timeline");
}


// 4. Post a text and cancel it
// Expected: cancel successfully and will be back to timeline
testName = "Regression Test " + countTest + " - post a text and cancel it";
countTest++;
UIALogger.logStart(testName);

// Execution steps
naviBar.elements()[3].buttons()["Compose"].tap();

var text = mainWindow.textViews()[0];
text.setValue(testName + " " + new Date().getTime());

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.navigationBars()["Compose"].buttons()[0].tap();
mainWindow.popover().actionSheet().buttons()["Discard"].tap(); 
//mainWindow.popover().actionSheet().buttons()["Save Draft"].logElementTree(); // Save Draft button
UIALogger.logMessage("Cancel the composition!");

// Verification
// a. the checkmark image
// b. the new post in timeline 
target.delay(1);
mainWindow.logElementTree();
// TODO: verify it's timeline screen
UIALogger.logPass(testName);


// 5. Read a text post
// Expected: see all text content in the post

testName = "Regression Test " + countTest + " - read a post";
countTest++;
UIALogger.logStart(testName);

// scroll right to the end
mainWindow.sliders()[0].dragToValue(1);

mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].tap();
//application.elements()[1].logElementTree();
application.elements()[1].scrollViews()[0].elements()["WACornerCloseButton"].tap();

UIALogger.logPass(testName);

// 6. Post a 1-line comment on a text post
// Expected: post successfully and see the new comment
// 7. Post a 10-line comment on a text post
// Expected: post successfully and see the new comment
// 8. Post a comment and cancel it on a text post
// Expected: cancel successfully and will be back to timeline
// 9. Browse timeline. Tap to the end of page and tap back to the top of page
// Expected: see the end of page and back to top successfully

testName = "Regression Test " + countTest + " - browse timeline";
countTest++;
UIALogger.logStart(testName);

UIATarget.localTarget().dragFromToForDuration({x:100, y:200}, {x:500, y:200}, 0.5);
target.delay(3);
UIATarget.localTarget().dragFromToForDuration({x:500, y:200}, {x:100, y:200}, 1);
target.delay(3);
UIATarget.localTarget().dragFromToForDuration({x:100, y:200}, {x:500, y:200}, 1);

UIALogger.logPass(testName);


// 10. Post a photo (take photo) (iphone/ipad2 only)
// Expected: post successfully and see the new post
// TODO: determin if the device is iphone or ipad 2

testName = "Regression Test " + countTest + " - post a photo (from library)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
naviBar.elements()[3].buttons()["Compose"].tap();

var text = mainWindow.textViews()[0];
text.setValue("a photo (from library)");

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.buttons()["PLCameraButtonIcon"].tap();
mainWindow.popover().tableViews()[0].cells()[0].tap();
mainWindow.popover().tableViews()[1].cells()[0].tap();
target.delay(1);
mainWindow.navigationBars()["Compose"].buttons()[1].tap();

// wait for action completed
while (mainWindow.elements()["In progress"].value() == 1) {
        target.delay(1);
}

UIALogger.logMessage("Post a photo (from library)");

// Verification
// a. the checkmark image
// b. the new post in timeline 
target.delay(1);
mainWindow.logElementTree();
// TODO: verify it's timeline screen
UIALogger.logPass(testName);


// 13. Post 10 photos (from library)
// Expected: post successfully and see the new post
testName = "Regression Test " + countTest + " - post 10 photos (from library)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
naviBar.elements()[3].buttons()["Compose"].tap();

var text = mainWindow.textViews()[0];
text.setValue("10 photos (from library)");

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

for (count = 1; count <= 10; count++) {
    mainWindow.buttons()["PLCameraButtonIcon"].tap();
    mainWindow.popover().tableViews()[0].cells()[0].tap();
    mainWindow.popover().tableViews()[1].cells()[0].tap();
    target.delay(1);
}
mainWindow.navigationBars()["Compose"].buttons()[1].tap();

// wait for action completed
while (mainWindow.elements()["In progress"].value() == 1) {
        target.delay(1);
}

UIALogger.logMessage("Post 10 photos (from library)");

// Verification
// a. the checkmark image
// b. the new post in timeline 
mainWindow.logElementTree();



// TODO: verify it's timeline screen
UIALogger.logPass(testName);


// 14. Post a photo and cancel it
// Expected: cancel successfully and will be back to posts

testName = "Regression Test " + countTest + " - post a photo and cancel it";
countTest++;
UIALogger.logStart(testName);

// Execution steps
naviBar.elements()[3].buttons()["Compose"].tap();

var text = mainWindow.textViews()[0];
text.setValue("a photo (from library)");

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.buttons()["PLCameraButtonIcon"].tap();
mainWindow.popover().tableViews()[0].cells()[0].tap();
mainWindow.popover().tableViews()[1].cells()[0].tap();
target.delay(1);
mainWindow.navigationBars()["Compose"].buttons()[0].tap();
mainWindow.popover().actionSheet().buttons()["Discard"].tap(); 

UIALogger.logPass(testName);

// 15. Read a photo post
// Expected: see the text if any and the photo covExpected. tap the photo covExpected and browse all photos successfully

testName = "Regression Test " + countTest + " - read a photo post";
countTest++;
UIALogger.logStart(testName);

// scroll right to the end
mainWindow.sliders()[0].dragToValue(1);

mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].tap();
//application.elements()[1].logElementTree();
application.elements()[1].scrollViews()[0].elements()["WACornerCloseButton"].tap();

UIALogger.logPass(testName);

// 16. Post a 1-line comment on a photo post 
// Expected: post successfully and see the new comment
// 17. Post a 10-line comment on a photo post 
// Expected: post successfully and see the new comment
// 18. Post a comment and cancel it on a photo post 
// Expected: cancel successfully and will be back to timeline
// 19. Save a draft and delete it (ipad only)
// Expected: save a draft and delete it successfully
testName = "Regression Test " + countTest + " - Save a draft and delete it";
countTest++;
UIALogger.logStart(testName);

naviBar.elements()[3].buttons()["Compose"].tap();
var text = mainWindow.textViews()[0];
text.setValue(testName);

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.buttons()["PLCameraButtonIcon"].tap();
mainWindow.popover().tableViews()[0].cells()[0].tap();
mainWindow.popover().tableViews()[1].cells()[0].tap();
// discard it
mainWindow.navigationBars()["Compose"].buttons()[0].tap();
mainWindow.popover().actionSheet().buttons()["Save Draft"].tap();
target.delay(5);
UIALogger.logMessage(testName);
// compose the draft
naviBar.elements()[3].buttons()["Compose"].tap();
mainWindow.popover().navigationBars()["Drafts"].buttons()["Edit"].tap();
mainWindow.popover().elements()[2].logElementTree();
mainWindow.popover().elements()[2].cells()[1].elements()[0].tap(); // delete switch
mainWindow.popover().elements()[2].cells()[1].elements()[2].tap(); // confirm deletoin button
mainWindow.popover().navigationBars()["Drafts"].buttons()["Done"].tap();

UIALogger.logPass(testName);

// 20. Save a draft and post it (ipad only)
// Expected: save a draft and post it successfully 
testName = "Regression Test " + countTest + " - Save a draft and delete it";
countTest++;
UIALogger.logStart(testName);

naviBar.elements()[3].buttons()["Compose"].tap();
var text = mainWindow.textViews()[0];
text.setValue(testName);

//mainWindow.navigationBars()["Compose"].buttons()[0].logElementTree(); // Cancel Button
//mainWindow.navigationBars()["Compose"].buttons()[1].logElementTree(); // Done Button

mainWindow.buttons()["PLCameraButtonIcon"].tap();
mainWindow.popover().tableViews()[0].cells()[0].tap();
mainWindow.popover().tableViews()[1].cells()[0].tap();
// discard it
mainWindow.navigationBars()["Compose"].buttons()[0].tap();
mainWindow.popover().actionSheet().buttons()["Save Draft"].tap();
target.delay(5);
UIALogger.logMessage(testName);
// compose the draft
naviBar.elements()[3].buttons()["Compose"].tap();
mainWindow.popover().elements()[2].cells()[1].tap(); // tap the draft
mainWindow.navigationBars()["Compose"].buttons()[1].tap(); // Done Button

UIALogger.logPass(testName);