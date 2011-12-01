var settings = {
  windows : false, // search for windows temp files (. -> _) (2x slower)
  swapFiles : false, // search for swap files (less useful) (2x slower)
}

var configFiles = [
  'config.php',               // phpBB, ExpressionEngine
  'configuration.php',        // Joomla
  'LocalSettings.php',        // MediaWiki
  'mt-config.cgi',            // Movable Type
  //  'mt-static/mt-config.cgi'   // Movable Type
  'settings.php',             // Drupal
  //  'system/config/config.php', // Contao
  'wp-config.php',            // Wordpress
];

/**
 *  Each backup file prefix/suffix is represented by an array, where
 *  arr[0] is the prefix and arr[1] is the suffix.
 */
var backupFileFormat = [
  // ['', '.save'],        // Nano crash file
  // ['', '.save.1'],      // Nano crash file (only saved sometimes)
  // ['', '.save.2'],      // Nano crash file (only saved sometimes)
  ['%23', '%23'],       // Emacs crash file (%23 is urlencoded hash (#))
  ['', '~'],            // Vim backup file and Gedit crash file
  ['', '.bak'],         // Common backup file extension
  ['', '.old'],         // Common backup file extension
];

/**
 *  Swap files only contain the changes since the last save, though that
 *  could still be very useful.
 */
var swapFileFormat = [
  ['', '.swp'],         // Vim
  ['', '.swo'],         // Vim
  ['.', '.swp'],        // Vim (on unix)
  ['.', '.swp'],        // Vim (on unix)
  ['._', ''],           // Mac OS X resource fork file (maybe useful)
];