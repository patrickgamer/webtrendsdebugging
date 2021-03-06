$(document).ready ->
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

  dcs.DCSext.tce_wa ='tce_wa'
  dcs.DCSext.tce_iw ='tce_iw'
  dcs.DCSext.tce_fs ='tce_fs'

  dcs.track()

  send = (dcs)->
    ->
      args = args:
        "DCSext.tce_it": "DCSext.tce_it"
        "DCSext.tce_ia": "DCSext.tce_ia"
        "DCSext.tce_iw": "DCSext.tce_iw"
        "DCSext.tce_fs": "DCSext.tce_fs"
        "DCSext.tce_wa": "DCSext.tce_wa"
        "DCSext.tls_qr": "DCSext.tls_qr"
        "DCSext.uem_evt": "DCSext.uem_evt"
        "DCSext.uem_ele": "DCSext.uem_ele__value"

      Webtrends.multiTrack args

  $('button').click(send(dcs))
