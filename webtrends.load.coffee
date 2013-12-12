class window.Toro

  fileExtRegex : /(?:\.([^.]+))?$/

  runRule : (stopFn, factors)->
    (toro)->
      (ev)->
        return true unless stopFn.call(toro)
        uem_ele = $(this).attr("id") # Element used
        uem_evt = $(this).data("etype") # Trigger event type
        toro.webtrendsCall factors, uem_evt, uem_ele
        return true

  webtrendsCall : (factors, uem_evt, uem_ele)->
      args = args:
        "DCSext.tce_it": factors["1"] # Interaction type
        "DCSext.tce_ia": factors["0"] # Interaction activity
        "DCSext.tce_iw": @countFactors(factors)
        "DCSext.tce_fs": @countFactors(factors) * factors["0"] # The final weight score
        "DCSext.tce_wa": @stringifyFactors(factors) # Which weightings are applied
        # Not ready yet: 'tls_lt': factors['4'], // Lead type
        "DCSext.tls_qr": factors["6"] # Data quality rating
        "DCSext.uem_evt": uem_evt
        "DCSext.uem_ele": uem_ele

      Webtrends.multiTrack args
      on
  #
  #	 * The rules object contain all the scoring rules. Due to challenges with CSV
  #	 * reads on the fly, the new structure will be JSON.
  #	 *
  #	 * Values that aren't going to be used should be set to NULL
  #	 *		NOTE: null != 0, if you want to pass a zero value, set it explicitly
  #	 
  baseline: (gg) ->
    if not @acceptableURL(["toro.com/reelmaster", "toro.com/leaderboard"])
      return false
    # Scores taken from Weighting Calculations sheet in 'Scoring Model.xlsx'
    factors =
      0: 1 # Is this a tracked event? (pageload = yes)
      1: 0 # Is the visitor completing a conversion? (not on page load)
      2: 0 # Are there special characteristics of the content? For example, is it "high value" content? (defalt = no)
      3: 0 # How important is the interation?
      4: 0 # Are there special characteristics of the organization this visitor belongs to? For example, is this a "target" account? TODO: Needs to be implemented.
      5: 0 # Are there special characteristics of the produce the visitor is interacting with? For example, is it a "high value" product? Not being used at this time.
      6: @getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?

    uriQuery = window.location.search
    
    # not currently in use, need to be avialable from Toro's side
    #			ngf = window.toro.getCookie('GM_NGF_ID'),
    #			skip = window.toro.getCookie('GM_SKIP'),
    #			mkt = window.toro.getCookie('GM_MKT_ID'),
    #			territory = window.toro.getCookie('GM_TERRITORY'), 
    eloquaID = @getGUID()
    
    # viewsALeaderboardProductPage
    factors["3"] = 2  if @acceptableURL(["toro.com/leaderboard/greensmaster", "toro.com/leaderboard/reelmaster", "toro.com/leaderboard/groundsmaster", "toro.com/leaderboard/workman", "toro.com/leaderboard/procore", "toro.com/leaderboard/multipro", "toro.com/leaderboard/irrigation", "toro.com/leaderboard/specialty"]) # Business score
    
    # viewsLeaderboardDistributorContactInfo
    if @acceptableURL("toro.com/leaderboard/contact")
      factors["1"] = 1 # Is the visitor completing a conversion
      factors["3"] = 3 # Business score
    
    # viewsMicrositeDistributorContactInfo
    if @acceptableURL("toro.com/request/distrib.cgi") and window.location.pathname.toLowerCase().indexOf("site_id=9") is 0
      factors["1"] = 1 # Is the visitor completing a conversion
      factors["3"] = 3 # Business score

    gg.DCSext.tce_wa = @stringifyFactors(factors) # This should be set, but I'm not really sure how.
    gg.DCSext.tce_iw = @countFactors(factors)
    gg.DCSext.tce_fs = @countFactors(factors) * factors["0"]
    return true

  ###
  Toro Solution
  
  Unfortunately, we don't use "use strict" because of so many external
  dependancies.
  
  This code is intended to be minified before deployment to production.
  ###
  logerrors: ()->
    on
  $log: (nname, gvalue) ->
    "use strict"
    i = 0
    test = window.toro.logerrors #if not present, default to false
    return false  if not test or not window.console
    if $type(gvalue) is "array"
      console.log "parameter " + nname + " has length of " + gvalue.length
      i = 0
      while i < gvalue.length
        window.console.log nname + "[" + i + "] = " + gvalue[i]
        i++
    #end output loop
    else if $type(gvalue) is "undefined"
      console.log nname #just dump the first parameter as a message
    else
      console.log nname + " has a value of " + gvalue
    true
  getURLParameter: (paramName) ->
    searchString = window.location.search.substring(1)
    i = undefined
    val = undefined
    params = searchString.split("&")
    i = 0
    while i < params.length
      val = params[i].split("=")
      return unescape(val[1])  if val[0] is paramName
      i++
    null
  getCookie: (name) ->
    nameEQ = name + "="
    ca = document.cookie.split(";")
    c = undefined
    i = 0
    value = null
    i = 0
    while i < ca.length
      c = ca[i]
      c = c.substring(1, c.length)  while c.charAt(0) is " "
      value = c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
      i++
    return null  if value.toLowerCase() is "undefined"  if value?
    value

  setCookie: (name, value, days) ->
    date = new Date()
    expires = ""
    if days
      date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
      expires = "; expires=" + date.toGMTString()
    else
      expires = ""
    document.cookie = name + "=" + value + expires + "; path=/"

  $type: (obj) ->
    "use strict"
    ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

  stringifyFactors: (gg) ->
    "use strict"
    flist = []
    for factor, value of gg
      if value > 0 and value?
        flist.push factor.toString()
    
    flist.join ','

  countFactors: (gg) ->
    "use strict"
    total = 0 # Sum of scores
    for factor, value of gg
      # Don't count the 0th factor
      total += value  if factor isnt "0" and @$type(value) is "number"
    total # It'll be 0 if no valid factors are present (not null)

  getFileExtension: (href) ->
    "use strict"
    @fileExtRegex.exec(href)[1]

  isDownload: (href, extensionList) ->
    extension = @getFileExtension href
    extension in extensionList

  acceptableURL: (list) ->
    ltype = @$type(list)
    href = window.location.href.replace /.*toro\.com/i, 'toro.com'
    checker = (hole, key) ->
      not not hole.match(key)

    if ltype is "string"
      return checker(href, list)
    else if ltype is "array"
      for url in list
        if checker(href, url)
          return yes
    return no
        
  getGUID: ->
    
    ###
    This funciton depends on the GUID cookie already being set by the Eloqua
    code further down the page form WT code (ran synchronously).
    ###
    
    # http://topliners.eloqua.com/message/9104#9104
    # http://code.google.com/p/eloqua-tracking/source/browse/#svn%2Ftrunk
    # now.eloqua.com/visitor/v200/svrGP.aspx?pps=70&siteid=117201930&ref=http://www.toro.com/en-ca/pages/default.aspx&ms=791
    guid = undefined
    elqVer = "v200" # this should be double-checked to match Toro's settings
    eguid = @getCookie("eguid")
    # It's not null
    return eguid  if eguid # Return value from the cookie already set (no AJAX call)
    $.ajax
      url: ((if document.location.protocol is "https:" then "https://secure" else "http://now")) + ".eloqua.com/visitor/" + elqVer + "/svrGP.aspx"
      async: false
      cache: true
      data:
        pps: 70
        siteid: 117201930
        ref: location.href
        ms: new Date().getMilliseconds()

      dataType: "script"
      success: ->
        
        # var elqGUID;
        if typeof @GetElqCustomerGUID is "function"
          guid = @GetElqCustomerGUID()
        else
          false

    @setCookie "eguid", guid, 400
    eguid # If not already set, set cookie then return guid

  # End getGUID	
  binder: (selector, etype, thefunc) ->
    
    # SP continues to be difficult for modern JS architecture, delegating event
    #			listeners instead of binding directly. This should be updated if Toro upgrades jQuery
    #		
    $("body").delegate selector, "mouseenter", (etype) ->
      $(this).data "etype", etype
      yes

    elements = $(selector)
    if elements.length > 0
      elements.bind etype, thefunc
    else
      $("body").delegate selector, etype, thefunc

  init: (wtinstance, @rules) -> #gg = dcs object, ff = function callback after completion
    # Initialization function for toro
    # Assumes toro.rules has already been defined.
    #run the baseline first
    @baseline wtinstance
    # Loop through all the rules, and apply the event listeners
    for rule in @rules
      if rule.etype? # Only attempt to bind where event type defined
        unless rule.selector
          selector = ".rules[id=\"#{rule.id}\"]"  if rule.id
        else # Otherwise look for an id
          selector = rule.selector
        @binder selector, rule.etype, rule.run(@) # Run the toro.binder function

window.toro = new window.Toro()

rules = [
  name: "clicksSelectCourseLink"
  selector: "div.bar-box span.add" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard"])
    ,
      0: 1 # Is this a tracked event?
      3: 1 # Business score
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksAllQuotesLink"
  selector: "a#show-all:contains(\"All Quotes\")" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/location"])
    ,
      0: 1 # Is this a tracked event?
      3: 2 # Business score
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksGolfCoursePlaceholder"
  selector: ".map"
  id: ""
  etype: "mouseenter"
  run:( (toro)->
    ->
      return false  unless toro.acceptableURL(["toro.com/leaderboard/location"])
      $(".map").data "mapcount", 0
      $(".map").gmap "find", "markers", {}, (marker, isFound) ->
        mapcount = $(".map").data("mapcount")
        if isFound
          if $(marker).data('mapbind')
            return false
          mapcount += 1
          $(".map").data "mapcount", mapcount
          $(marker).data 'mapbind', true
          $(marker).click (ev) ->
            
            ###
            All the factor variables need to be set here b/c they won't
            read up to the page level scope
            ###
            factors =
              0: 1 # Is this a tracked event?
              3: 1 # Business score
              6: toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?

            uem_ele = $(this).attr("id") # Element used alternatively just use string "map-marker"
            uem_evt = $(this).data("etype") # Trigger event type
            window.toro.webtrendsCall factors, uem_evt, uem_ele
  )
,
  name: "clicksProductInGolfCoursePopup"
  selector: "div.product a" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/location"])
    ,
      0: 1 # Is this a tracked event?
      3: 1 # Business score
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksNextQuoteInGolfCoursePopup"
  selector: "div.mapinfo div.jcarousel-next, div.mapinfo div.jcarousel-prev" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/location"])
    ,
      0: 1 # Is this a tracked event?
      3: 1 # Business score
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnTrackedDocumentLink"
  selector: "body" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "mouseenter" # The type of event function to be called by jQuery
  run: ( (toro)->
    ->
      return false if not window.toro.acceptableURL(["toro.com/leaderboard","toro.com/reelmaster"]) or $("body").data "pdf-bind"
      $("a").each ()->
        return false if $(this).data "pdf-bind" or not window.toro.isDownload($(this).attr("href"), ["pdf"])
        #$(this).data "pdf-bind",true
        $(this).click ()->
          factors =
            0: 1 # Is this a tracked event? (pageload = yes)
            3: 2 # Business score
            6: window.toro.getCookie "GM_CONF_ID"
          uem_ele = $(this).attr "id" # Element used alternatively just use string "map-marker"
          uem_evt = $(this).data "etype" # Trigger event type
          window.toro.webtrendsCall factors, uem_evt, uem_ele
      $("body").data "pdf-bind",true
  )#end of run
,
  name: "clicksLearnMoreButton"
  selector: "a.btn-more span:contains(\"Learn More\")" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 3 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksShareFacebookWidget"
  selector: "span.st-facebook-counter" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksShareTwitterWidget"
  selector: "span.st-twitter-counter" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/greensmaster", "toro.com/leaderboard/reelmaster", "toro.com/leaderboard/groundsmaster", "toro.com/leaderboard/workman", "toro.com/leaderboard/procore", "toro.com/leaderboard/multipro", "toro.com/leaderboard/irrigation", "toro.com/leaderboard/specialty"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksShowMoreQuotes"
  selector: "div.btn-more-quotes:contains(\"Show more quotes\")" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/greensmaster", "toro.com/leaderboard/reelmaster", "toro.com/leaderboard/groundsmaster", "toro.com/leaderboard/workman", "toro.com/leaderboard/procore", "toro.com/leaderboard/multipro", "toro.com/leaderboard/irrigation", "toro.com/leaderboard/specialty"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 1 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnLeaderboardCourseNameLink"
  selector: "form.course-form a[href*=\"setNGF\"]" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/contact/index.cgi"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 4 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksSubmitNewQuoteButton"
  selector: "div.addquote-form input.btn[name='submit']" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/quote"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 3 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksSubmitInfoRequestButton"
  selector: "fieldset.info-form input#b-submit" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/info"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      1: 1 # Is the visitor completing a conversion
      3: 5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksEnewsSubscribeButton"
  selector: "form#mc-embedded-subscribe-form .btn-holder .btn" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/leaderboard/subscribe"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnCourseNameLink"
  selector: ".left-column .row a" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/request/contact.cgi"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 4 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnSeriesImage"
  selector: "div img[id^=\"RM_\"]" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 0.5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnHomepageImageRotationControl"
  selector: "div.slide-arrows a.next, div.slide-arrows a.previous" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 0.5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnRequestInfoContinueButton"
  selector: "input.btn#b-submit" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL("toro.com/request") and window.toro.getURLParameter("site_id") is "9"
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnRequestInfoSubmitRequestButton"
  selector: "input.btn#b-submit" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
      window.toro.acceptableURL("toro.com/request/step2")
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      1: 1 # Is the visitor completing a conversion
      3: 3 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnSubscribeToNewsletterSubmitButton"
  selector: "#formElement12 > div:nth-child(1) > div:nth-child(1) > p:nth-child(1) > input:nth-child(1)" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/Subscribe_GroundsforSuccess"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnSeriesThumbImage"
  selector: "div#ModelSelection img[id$=\"_Series\"]" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 0.5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnGalleryThumbImage"
  selector: "div[id^=\"Stage_Rectangle\"]" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster/gallery"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 0.5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnTakeTheTourButton"
  selector: "img#TakeTheTour" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster/products"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 2 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnProductHotSpot"
  selector: "div#Stage div[id$=\"_hot_spot_icon\"]" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
        window.toro.acceptableURL(["toro.com/reelmaster/tour"])
    ,
      0: 1 # Is this a tracked event? (pageload = yes)
      3: 1 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
      6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksOnPerspectiveImage"
  selector: ".LeftSideImages" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.toro.runRule( ->
      window.toro.acceptableURL(["toro.com/reelmaster/tour"])
    ,
    0: 1 # Is this a tracked event? (pageload = yes)
    3: 0.5 # Is the visitor using a "high value" interaction/event with the content? (ex. video)
    6: window.toro.getCookie("GM_CONF_ID") # Are we sure we know what organization this visitor belongs to?
  )
]

# If it is null, don't do anything for this rule
# End for-rule
# End init function def'n
# End of toro definition

# WebTrends SmartSource Data Collector Tag v10.2.36
# Copyright (c) 2012 Webtrends Inc.	All rights reserved.
# Tag Builder Version: 4.1.0.33
# Created: 2012.08.24
$(document).ready ->
  window.webtrendsAsyncInit = ->
    dcs = new Webtrends.dcs()
    dcs.init
      dcsid: "dcsx399cuvz5bdjtqdgcadhf3_2t6d"
      domain: "statse.webtrendslive.com"
      timezone: 0
      i18n: true
      offsite: false
      download: false
      vtid: window.toro.getGUID() # From the helper function
      downloadtypes: "xls,doc,pdf,txt,csv,zip,docx,xlsx,rar,gzip,dwg,ppt,pptx"
      onsitedoms: "toro.com torodealer.com"
      fpcdom: ".toro.com"
      plugins:
        
        # hm:{src:"// s.webtrends.com/js/webtrends.hm.js"}
        WT_FPCDom:
          src: "//toro.com/Style%20Library/Toro/js/webtrends.fpcdom.js"

        yt:
          src: "//toro.com/Style%20Library/Toro/js/webtrends.yt.js"
          mode: "manual"
          dcsid: "dcsx399cuvz5bdjtqdgcadhf3_2t6d"

    window.toro.init(dcs, rules)
    dcs.track()

  # end webtrendsAsyncInit
  (->
    s = document.createElement("script")
    s.async = true
    s.src = "/Style%20Library/Toro/js/webtrends.min.js"
    s2 = document.getElementsByTagName("script")[0]
    s2.parentNode.insertBefore s, s2
    s3 = document.createElement("script")
    try
      # ...
      s.innerHTML = "Webtrends.addYTPlayer(player);" #Webtrends.addYTPlayer player
      s2 = $("script").filter((index) ->
        @innerHTML.match "var player;"
      ).get()
      if s2
        s2.parentNode.insertAfter s3, s2
    catch e
      # ...
      window.toro.$log(e)
    finally
      return
  
  #document.write("<script type='text/javascript' src='/Style%20Library/Toro/js/webtrends.min.js'></script>");
  )()
#end ready() call
