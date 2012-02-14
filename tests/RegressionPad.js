function isTimelineVisible() {
    if (UIATarget.localTarget().frontMostApp().mainWindow().navigationBar().elements()["WALogo"].isValid() &&
        UIATarget.localTarget().frontMostApp().mainWindow().scrollViews()[0].elements()["WAPageShadowLeft"].isValid() &&
        UIATarget.localTarget().frontMostApp().mainWindow().sliders()[0].isValid()) {
        return true;
    }
    else {
        return false;
    }
}

function slideToEnd() {
    UIATarget.localTarget().frontMostApp().mainWindow().sliders()[0].dragToValue(1);
}

function flickToRight() {
    UIATarget.localTarget().flickFromTo({x:160, y:400}, {x:360, y:400});
}

function flickToLeft() {
    UIATarget.localTarget().flickFromTo({x:360, y:400}, {x:160, y:400});
}

function closePost() {
    UIATarget.localTarget().frontMostApp().elements()[1].scrollViews()[0].elements()["WACornerCloseButton"].tap(); // post close button
}

function compose() {
    UIATarget.localTarget().frontMostApp().mainWindow().navigationBar().elements()[3].buttons()["Compose"].tap(); // compose button
}

function composeCancel() {
    UIATarget.localTarget().frontMostApp().mainWindow().navigationBars()["Compose"].buttons()[0].tap(); // Cancel Button
}

function composeDone() {
    UIATarget.localTarget().frontMostApp().mainWindow().navigationBars()["Compose"].buttons()[1].tap(); // Done Button
}

function discard() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().actionSheet().buttons()["Discard"].tap(); 
}

function saveDraft() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().actionSheet().buttons()["Save Draft"].tap(); // Save Draft button
} 

function assertCheckmark() {
    return UIATarget.localTarget().frontMostApp().mainWindow().elements()["WAOverlayBezel-Checkmark"].isEnabled();
}

function assertDraft() {
    return UIATarget.localTarget().frontMostApp().mainWindow().popover().navigationBars()["Drafts"].isValid();
}

function editDraft() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().navigationBars()["Drafts"].buttons()["Edit"].tap();
}

function editDraftDone() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().navigationBars()["Drafts"].buttons()["Done"].tap(); 
}

function switchDraft() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().elements()[2].cells()[1].elements()[0].tap(); // delete switch
}
    
function deleteDraft() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().elements()[2].cells()[1].elements()[2].tap(); // confirm deletoin button
}

function tapDraft() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().elements()[2].cells()[1].tap(); // tap the draft
}

function tapCamera() {
    UIATarget.localTarget().frontMostApp().mainWindow().buttons()["PLCameraButtonIcon"].tap();
}

function fromLibrary() {
    UIATarget.localTarget().frontMostApp().mainWindow().popover().tableViews()[0].cells()[0].tap();
}

function pickPhoto() {
    // TODO: add picking by position
    UIATarget.localTarget().frontMostApp().mainWindow().popover().tableViews()[1].cells()[0].tap();
}



// 0.a update waveface if an prior build is installed
// Expected: update successfully
// TODO: Use Simulator Snapshot to achieve this later.
var countTest = 1
//var testName = "Regression Test " + countTest + " - update waveface";
//countTest++;
//UIALogger.logStart(testName);

//UIALogger.logPass(testName);


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

// validate if the waveface log shows
if (isTimelineVisible()) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName);
}


// 2. Post a text (1 line)
// Expected: post successfully and see the new post
// TODO: have a wait-till-next-item function
testName = "Regression Test " + countTest + " - post a text (1 line)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
mainWindow.logElementTree();
compose();

// 2.1 clean unexpected left draft
if (assertDraft()) {
    editDraft();
    switchDraft();
    deleteDraft();
    editDraftDone();
    UIALogger.logMessage("Clean unexpected left draft.");

    compose();
}

var text = mainWindow.textViews()[0];
var msg = testName + " " + new Date().getTime();
text.setValue(msg);

composeDone();

// scroll right to the end
slideToEnd();

// Verification
// a. the checkmark image
// b. the new post in timeline

if (assertCheckmark()) {
    UIALogger.logMessage("Checkmark shows!");
    UIALogger.logMessage("Post 1 line text!");
}
else {
    UIALogger.logFail(testName + " - no checkmark");
}

// TODO: verify if the new post is correct. 
// TODO: verify the new post display in timeline
// currently, only the name of photo post object is its context 
mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].logElementTree();
if (isTimelineVisible()) {
    UIALogger.logMessage("Back to timeline");
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName + " - not back to timeline");
}

// 3. Post a text (10 line)
// Expected: post successfully and see the new post

testName = "Regression Test " + countTest + " - post a text (10 line)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
compose();

text = mainWindow.textViews()[0];
msg = "";
for (var count=1; count <= 10; count++) {
    msg += (testName + " " + new Date().getTime() + "\n");
}
text.setValue(msg);

composeDone();

UIALogger.logMessage("Post 10 line text!");

// Verification
// a. the checkmark image
// b. the new post in timeline 
target.delay(1);
if (assertCheckmark()) {
    UIALogger.logMessage("Checkmark shows!");
}
else {
    UIALogger.logFail(testName + " - no checkmark");
}
target.delay(1);

if (isTimelineVisible()) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName + "- not back to timeline");
}


// 4. Post a text and cancel it
// Expected: cancel successfully and will be back to timeline
testName = "Regression Test " + countTest + " - post a text and cancel it";
countTest++;
UIALogger.logStart(testName);

// Execution steps
compose();

var text = mainWindow.textViews()[0];
text.setValue(testName + " " + new Date().getTime());

composeCancel();
discard();
UIALogger.logMessage("Cancel the composition!");

target.delay(1);

// verify it's timeline screen
if (isTimelineVisible()) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName);
}

// 5. Read a text post
// Expected: see all text content in the post

testName = "Regression Test " + countTest + " - read a post";
countTest++;
UIALogger.logStart(testName);

// scroll right to the end
slideToEnd();

mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].tap();
closePost();


if (isTimelineVisible()) {
    UIALogger.logPass(testName);
}
else {
    UIALogger.logFail(testName);
}


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

flickToLeft();
flickToRight();
flickToLeft();

UIALogger.logPass(testName);


// 10. Post a photo (from library)
// Expected: post successfully and see the new post
// TODO: determin if the device is iphone or ipad 2 for take photo

testName = "Regression Test " + countTest + " - post a photo (from library)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
compose();

var text = mainWindow.textViews()[0];
text.setValue(testName + " " + new Date().getTime());

tapCamera();
fromLibrary();
pickPhoto();
target.delay(1);
composeDone();

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
UIALogger.logPass(testName);


// 13. Post 10 photos (from library)
// Expected: post successfully and see the new post
testName = "Regression Test " + countTest + " - post 10 photos (from library)";
countTest++;
UIALogger.logStart(testName);

// Execution steps
compose();

var text = mainWindow.textViews()[0];
text.setValue(testName + " " + new Date().getTime());

for (count = 1; count <= 10; count++) {
    tapCamera();
    fromLibrary();
    pickPhoto();
    target.delay(1);
}
composeDone();


// Verification
// a. the checkmark image
// b. the new post in timeline 
// wait for action completed
while (mainWindow.elements()["In progress"].value() == 1) {
        target.delay(1);
}

UIALogger.logMessage("Post 10 photos (from library)");
mainWindow.logElementTree();
UIALogger.logPass(testName);


// 14. Post a photo and cancel it
// Expected: cancel successfully and will be back to posts

testName = "Regression Test " + countTest + " - post a photo and cancel it";
countTest++;
UIALogger.logStart(testName);

// Execution steps
compose();

var text = mainWindow.textViews()[0];
text.setValue(testName + " " + new Date().getTime());

tapCamera();
fromLibrary();
pickPhoto();
target.delay(1);
composeCancel();
discard(); 

UIALogger.logPass(testName);

// 15. Read a photo post
// Expected: see the text if any and the photo covExpected. tap the photo covExpected and browse all photos successfully

testName = "Regression Test " + countTest + " - read a photo post";
countTest++;
UIALogger.logStart(testName);

// scroll right to the end
slideToEnd();

mainWindow.scrollViews()[0].elements()[mainWindow.scrollViews()[0].elements().length - 1].tap();
//application.elements()[1].logElementTree();
closePost();

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

compose();
var text = mainWindow.textViews()[0];
text.setValue(testName);

tapCamera();
fromLibrary();
pickPhoto();
target.delay(1);
// discard it
composeCancel();
saveDraft();
target.delay(5);
UIALogger.logMessage(testName);
// compose the draft
compose();
editDraft();
switchDraft();
deleteDraft();
editDraftDone();

UIALogger.logPass(testName);

// 20. Save a draft and post it (ipad only)
// Expected: save a draft and post it successfully 
testName = "Regression Test " + countTest + " - Save a draft and post it";
countTest++;
UIALogger.logStart(testName);

compose();
var text = mainWindow.textViews()[0];
text.setValue(testName);

tapCamera();
fromLibrary();
pickPhoto();
target.delay(1);
// discard it
composeCancel();
saveDraft();
target.delay(5);
UIALogger.logMessage(testName);
// compose the draft
compose();
tapDraft();
composeDone();



UIALogger.logPass(testName);

