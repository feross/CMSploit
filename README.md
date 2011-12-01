# CMSploit

Full explanation: http://www.feross.org/cmsploit/

I originally wrote this as a Chrome extension to test the current site you're visiting for the presence of temporary config files. However, I decided to rewrite it using [PhantomJS](http://www.phantomjs.org/), a headless WebKit browser with JavaScript API, so I could run it over the top 200,000 sites automatically and get a sense of how prevalent this problem is.

Finally, I decided to rewrite it a final time in [Node.js](http://nodejs.org/), [CoffeeScript](http://jashkenas.github.com/coffee-script/), and [jsdom](https://github.com/tmpvar/jsdom) so I could easily parallilize the script and test for subfolders and subdomains (as described above). I enumerate all links on each site's homepage and test each subdirectory/subdomain that they link to (the theory being that if a site runs a blog or forum, they'll link to it from the homepage). This implementation is currently unfinished. It has a bug where it runs out of file descriptors and can't open any more sockets that I can't figure out. If you feel like improving it, feel free to send a pull request on GitHub. I might finish it at some point.

All three implementations are in the repo:

- v1: ChromeExtension
- v2: PhantomJS
  - Depends on PhantomJS
  - If you get the error message "phantomjs: cannot connect to X server?", then install Xvfb per [this faq](http://code.google.com/p/phantomjs/wiki/FAQ).
- v3: NodeJS (unfinished)
  - Depends on node modules: coffee-script, jquery, jsdom