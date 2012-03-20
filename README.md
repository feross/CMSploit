# CMSploit

Nearly 1% of websites built with a content management system (like WordPress or Joomla) are unknowingly exposing their database password to anyone who knows where to look.

Read full explanation here: http://www.feross.org/cmsploit/

## TL;DR — Summary of the Problem

Using a text editor to modify content management system (CMS) configuration files (like wp-config.php) could expose your database password to the world. Several popular text editors like Vim and Emacs automatically create backup copies of the files you edit, giving them names like “wp-config.php~” and “#wp-config.php#”. If the text editor crashes or the SSH connection drops during editing, then the temporary backup files may not be cleaned up correctly. This means that the CMS config file (which contains the database password) could accidentally be made public to anyone who knows where to look.

Most servers, including the ubiquitous Apache, will happily serve the plaintext of .php~ and .php# files without passing them through the PHP preprocessor first, since they don’t have the .php file extension. Thus, your sensitive database credentials are just one GET request away from being accessed by a malicious party.

I wrote an automatic program, which I call CMSploit, to test for the prevalence of this issue across the wider web. I tested the top 200,000 websites (as ranked by Quantcast) and found that 0.11% of websites are vulnerable. If we eliminate non-CMS sites, and just look at CMS-powered websites, then we find that 0.77% of websites running a CMS have publicly-visible config files.

If you want all the gory details, then read the full explanation here: http://www.feross.org/cmsploit/

## Implementations: Chrome extension, PhantomJS, and NodeJS.

I originally wrote this as a Chrome extension to test the current site you're visiting for the presence of temporary config files. However, I decided to rewrite it using [PhantomJS](http://www.phantomjs.org/), a headless WebKit browser with JavaScript API, so I could run it over the top 200,000 sites automatically and get a sense of how prevalent this problem is.

Finally, I decided to rewrite it another time in [Node.js](http://nodejs.org/), [CoffeeScript](http://jashkenas.github.com/coffee-script/), and [jsdom](https://github.com/tmpvar/jsdom) so I could easily parallilize the script and test for subfolders and subdomains (as described above). I enumerate all links on each site's homepage and test each subdirectory/subdomain that they link to (the theory being that if a site runs a blog or forum, they'll link to it from the homepage). This implementation is currently unfinished. It has a bug where it runs out of file descriptors and can't open any more sockets that I can't figure out. If you feel like improving it, feel free to send a pull request on GitHub. I might finish it at some point.

All three implementations are in the repo:

- v1: ChromeExtension
- v2: PhantomJS
  - Depends on PhantomJS
  - If you get the error message "phantomjs: cannot connect to X server?", then install Xvfb per [this faq](http://code.google.com/p/phantomjs/wiki/FAQ).
- v3: NodeJS (unfinished)
  - Depends on node modules: coffee-script, jquery, jsdom