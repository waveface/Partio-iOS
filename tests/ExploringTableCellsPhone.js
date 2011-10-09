var target = UIATarget.localTarget();

//target.delay(5);

var application = target.frontMostApp();
var mainWindow = application.mainWindow();
var tableView = mainWindow.tableViews()[0];

UIALogger.logMessage("Number of cells " + tableView.cells().length);

for (var currentCellIndex = 0; currentCellIndex < tableView.cells().length; currentCellIndex++) {
    var currentCell = tableView.cells()[currentCellIndex];
    UIALogger.logStart("Testing table option " + currentCell.name());
    tableView.scrollToElementWithName(currentCell.name());
    target.delay(1);
    currentCell.tap();
    target.delay(1);
    
    UIATarget.localTarget().captureScreenWithName(currentCell.name());
    mainWindow.navigationBar().leftButton().tap();
    target.delay(1);
    UIALogger.logPass("Testing table option " + currentCell.name());
}