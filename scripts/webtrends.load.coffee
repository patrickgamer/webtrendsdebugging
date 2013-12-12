###
  This code provides proper scoping and encapsulation of variables being fed into Webtrends
###
class window.Example
  runRule : (stopFn, factors)->
    (example)->
      (ev)->
        return true unless stopFn.call(example)
        uem_ele = $(this).attr("id") # Element used
        uem_evt = $(this).data("etype") # Trigger event type
        example.webtrendsCall factors, uem_evt, uem_ele
        console.log "running rule"
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

  baseline: (gg) ->
    factors =
      0: 1 # Is this a tracked event? (pageload = yes)
      1: 0 # Is the visitor completing a conversion? (not on page load)
      2: 0 # Are there special characteristics of the content? For example, is it "high value" content? (defalt = no)
      3: 0 # How important is the interation?
      4: 0 # Are there special characteristics of the organization this visitor belongs to? For example, is this a "target" account? TODO: Needs to be implemented.
      5: 0 # Are there special characteristics of the produce the visitor is interacting with? For example, is it a "high value" product? Not being used at this time.
      6: "DSSADI134321412" # Are we sure we know what organization this visitor belongs to?

    factors["1"] = 1 # Is the visitor completing a conversion
    factors["3"] = 3 # Business score
    
    gg.DCSext.tce_wa = @stringifyFactors(factors) # This should be set, but I'm not really sure how.
    gg.DCSext.tce_iw = @countFactors(factors)
    gg.DCSext.tce_fs = @countFactors(factors) * factors["0"]
    return true

  binder: (selector, etype, thefunc) ->
    # SP continues to be difficult for modern JS architecture, delegating event
    #     listeners instead of binding directly. This should be updated if example upgrades jQuery
    #   
    $("body").delegate selector, "mouseenter", (etype) ->
      $(this).data "etype", etype
      yes
    elements = $(selector)
    if elements.length > 0
      elements.bind etype, thefunc
    else
      $("body").delegate selector, etype, thefunc

  init: (wtinstance, @rules) -> 
    ### this kicks off the binding for tracking ###
    for rule in @rules
      if rule.etype? 
        ### Only attempt to bind where event type defined ###
        unless rule.selector
          selector = ".rules[id=\"#{rule.id}\"]"  if rule.id
        else # Otherwise look for an id
          selector = rule.selector
        @binder selector, rule.etype, rule.run(@) # Run the example.binder function

###
  instantiation of the example code
###
window.example = new window.Example()
###
  Note in these rules that the function defines new values for existing variables. These
  variables are passed in as return values.
###
rules = [
  name: "clicksFirstButton"
  selector: "#first" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.example.runRule( ->
        true
    ,
      0: 1 # Is this a tracked event?
      3: 1 # Business score
      6: "aaa3" # Are we sure we know what organization this visitor belongs to?
  )

,
  name: "clicksSecondButton"
  selector: "#second" # A CSS selector used by jQuery [optional]
  id: "" # An ID of the specific element in question [optional]
  etype: "click" # The type of event function to be called by jQuery
  run: window.example.runRule( ->
        true
    ,
      0: 3 # Is this a tracked event?
      3: 2 # Business score
      6: "bbb1" # Are we sure we know what organization this visitor belongs to?
  )
]

###
# WebTrends SmartSource Data Collector Tag v10.2.36
# Copyright (c) 2012 Webtrends Inc.	All rights reserved.
# Tag Builder Version: 4.1.0.33
# Created: 2012.08.24
###

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
      vtid: "werwe23423423234"# From the helper function
      downloadtypes: "xls,doc,pdf,txt,csv,zip,docx,xlsx,rar,gzip,dwg,ppt,pptx"
      onsitedoms: "example.com exampledealer.com"
      fpcdom: ".example.com"
    window.example.init(dcs, rules)
    dcs.track()

  # end webtrendsAsyncInit
  (->
    s = document.createElement "script"
    s.async = true
    s.src = "//s.webtrends.com/js/webtrends.js"
    s2 = document.getElementsByTagName("script")[0]
    s2.parentNode.insertBefore s,s2
    on
  )()