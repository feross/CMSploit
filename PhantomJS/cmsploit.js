/* TODO
  - Search in subdomains and subfolders for CMSes
*/

phantom.injectJs('lib/jquery.js');
phantom.injectJs('util.inc.js');
phantom.injectJs('settings.inc.js');

var fs = require('fs');

/**
 *  Build up an array of all file names to test for.
 */
function allTestFiles() {
  var ret = [];

  var tempFileFormats = $.merge([], backupFileFormat); // clone array
  if (settings.swapFiles) {
    $.merge(tempFileFormats, swapFileFormat); // merge arrays
  }

  $.each(configFiles, function(i, configFile) {
    $.each(tempFileFormats, function(i, tempFormat) {
      var file = tempFormat[0] + configFile + tempFormat[1];
      ret.push(file);

      // On windows, vim replaces dots with underscores in backup file.
      if (settings.windows) {
        var windowsFile = file.replace(/\./gi, '_');
        ret.push(windowsFile);
      }
    });
  });

  return ret;
}
var testFiles = allTestFiles();

/**
 *  Test a given hostname (ex: feross.org) for publicly-visible
 *  CMS configuration files.
 */
function testHostname(hostname, callback) {
  if (!hostname) {
    callback && callback();
    return;
  }
  var origin = 'http://'+hostname+'/';

  var notFoundPages = [];

  function checkFile(i) {
    if (i > testFiles.length - 1) {
      callback && callback();
      return;
    };

    var url = origin + testFiles[i];
    $.ajax({
      url: url,
      success: function(data, textStatus, jqXHR) {
        // Data looks the same as a Not Found page, so ignore it
        var notFound;
        $.each(notFoundPages, function(i, notFoundPage) {
          if (data.trunc(100) == notFoundPage.trunc(100)) {
            notFound = true;
          }
        });
        if (notFound) return;

        // Data that looks like an HTML page
        var pageHead = data.trunc(100).toLowerCase();
        if (pageHead.indexOf('<!doctype') != -1 ||
            pageHead.indexOf('<!--') != -1 ||
            pageHead.indexOf('<html') != -1) {
          return;
        }
        console.log(url);
        onFoundFile(hostname, testFiles[i], data);
      },
      complete: function(jqXHR, textStatus) {
        i += 1;
        checkFile(i);
      }
    });
  }

  // When looking for password files, if we find a file that has a 200
  // code (success), but it looks like this Not Found page, then
  // ignore it.
  $.ajax({
    url: origin + 'TESTING_FOR_404_LULZ.php',
    success: function(data, textStatus, jqXHR){
      notFoundPages.push(data);
    },
    complete: function(jqXHR, textStatus) {
      // We need to test for a second type of Not Found page because
      // lots of servers act differently for URLs that contain %23,
      // for some reason.
      $.ajax({
        url: origin + '%23_TESTING_FOR_404_LULZ.php',
        success: function(data, textStatus, jqXHR){
          notFoundPages.push(data);
        },
        complete: function(jqXHR, textStatus) {
          checkFile(0);
        }
      });
    }
  });
}

function onFoundFile(hostname, filename, data) {
  var path = 'results/' + hostname;
  fs.makeDirectory(path);

  var f = fs.open(path + '/' + filename, 'w');
  f.write(data);
  f.flush();
  f.close();
}

function startTest() {
  var sites = fs.open('sites.txt', 'r').read();

  if (!fs.exists('results')) {
    fs.makeDirectory('results');
  }

  // We track the number of the last site we tested, so that if we restart the program
  // for some reason, we can skip all the sites we already tested.
  if (fs.exists('results/lastNum.txt')) {
    var f = fs.open('results/lastNum.txt', 'r');
    var lastNum = parseInt(f.read());
    f.close();
  } else {
    var lastNum = 0;
  }

  var re = /(\d+)\t(.+)/g;
  function testNextSite() {
    var result;
    if ((result = re.exec(sites)) != null) {
      var num = result[1];
      var hostname = result[2];

      // Skip sites we've already tested
      if (num <= lastNum) {
        testNextSite();
        return;
      }

      console.log(hostname);
      testHostname(hostname, testNextSite);

      // Save that we've tested this site
      var numFile = fs.open('results/lastNum.txt', 'w');
      numFile.write(num);
      numFile.flush();
      numFile.close();
    }
  }

  for (var i = 0; i < 15; i++) {
    testNextSite();
  }
  // testNextSite();
}

startTest();
