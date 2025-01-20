

/**
 * @license
 */

/**
 * @version Desp 1.0.0-alpha
 *
 * @file Digital edition survival package
 * <p>
 * Combine images and text in a digital edition
 */

/**
 * @module Desp
 */

/**
 * @namespace Desp
 *
 * @classdesc root namespace
 */


/** how to embed a gams osd instance into your o:* html representation:
 *
 * include openseadragon.min.js into the head of your page,
 * create a div that holds the id "vwr-content" at the position you
 * want the vwr to appear and assign a fixed width and height to it,
 * include the gamsOsd.js after #vwr-content,
 * and voilÃƒ , you did it!
 *
 *
 *
 * the pid of your o:* will be picked out of the url of the object,
 * and all the images referenced in your object will be displayed in
 * the vwr.
 *
 * now you can start to style your very own osd  vwr...
 *
 *
 **/

/**
 * digital edition survival package
 * doc for myself...
 * at the moment...
 * 3 scripts are needed
 * osd i should make the osd a property of the edition...
 * like Desp.osd
 * gamsEdition
 * bs-scroll the edition
 */

//TODO paket soll enthalten openseadragon min + gamsOsd und gamsosd min

function getParams(query) {
    var params = {
    };
    query.replace(/([^=&]+)=([^&]*)/g, function (string, key, value) {
        params[key] = value;
    });
    return params;
};

/**
 * Loads an array of info.jsonS via ajax and initializes the osd
 * when successful
 * @function
 * @param {string} url - the url to where to get the list of images
 * @param {object} options - the options for initialization
 * TODO urls should be obtained from the manifest! we should write
 * a function that gets us all info.jsonS
 */

function loadExternalTileSources (url, options) {
    
    // TODO using promises for that maybe?
   
 
    jQuery.ajax({
        url: url,
        dataType: 'json',
        async: true,
        success: function (json) {
	options.tileSources = json.images;
            initOsd(options);
        },
        
        error: function () {
            console.log("Failed loading " + url);
        }
    })
};

/**
 * @function
 * @param options
 */

function getTileSourcesUrl (options) {
    
    // TODO error handling if no pid is
    // TODO you can hand over a pid or an url to the iiifp interface
    
    var manifestUri;
    
    if (options.pid) {
        manifestUri = options.pid + "/sdef:IIIF/getTileSources";
    } else {
        var query = window.location.search.substring(1);
        
        manifestUri = getParams(query).manifest
    }
    
    return manifestUri;
};


/**
 * @constructor
 */


function gamsOsd(options) {
    // TODO what if user wants to explicitly specify tileSources
    
    if (options.tileSources) {
        initOsd(options);
    } else {
        var url = getTileSourcesUrl(options);
     	
console.log('test');
console.log(url);   
	loadExternalTileSources(url, options);
    }
};

/*

at first get an array of all ids of all pics that are in the site!
collect the ids from the json that should eventually lead to an iiifp,
at the moment i see the possibility for `{"id":"this-id", "service": "service-uri", "label": "this-label"} `

+ frag jo weg. personalisierter xml2json

var ids_of_pics_to_be_considered = [];

then look if scroll id is in the pic list as a href is in the nav list,
and if! fire

 */

/* TODO
 * look for the problem concerning the fullscreen api -
 * everytime you open it, the page scrolls down to the end and then opens the fullscreen
 * as far as i know.
 * this is a problem because the fullscreen always shows the last pic because of that.
 * not sure if the problem is in the osd or in the fullscreen api
 *
 * a possibility would be to enable the scroll thingy when full screen event is fired
 * consider problems from both ends! always!
 */


/**
 * @function
 */
function initOsd(options) {
    
    // make an edition property Edition.viewer - which is a widget. in our case it's osd
    var viewer = OpenSeadragon (options);
    
    if (options.source) {
        viewer.datastream = options.source;
    };
    
    /////////////////////////////////////////////////
    // ******************* edition.js starts here //
    ///////////////////////////////////////////////
    
    window.Desp = window.Desp || function (config) {
        return new Desp.Edition(config)
    };
    
    /**
     * init Edition
     */
    
    (function ($) {
        
        $.Edition = function (config) {
            jQuery.extend(true, this, config);
            
            this.init();
        };
        
        $.Edition.prototype = {
            init: function () {
                
                // new manifest
                var manifestUri = this.manifestUri;
                this.manifest = new $.Manifest(manifestUri)
            }
        }
    }
    (Desp));
    
    
    /**
     * IIIF
     */
    // borrowed from mirador's aeschylus
    
    (function ($) {
        
        $.Iiif = {
            
            getImageUrl: function (image) {
                
                if (! image.images[0].resource.service) {
                    id = image.images[0].resource[ 'default'].service[ '@id'];
                    id = id.replace(/\/$/, "");
                    return id;
                }
                var id = image.images[0].resource.service[ '@id'];
                id = id.replace(/\/$/, "");
                
                return id;
            },
            
            getVersionFromContext: function (context) {
                if (context == "http://iiif.io/api/image/2/context.json") {
                    return "2.0";
                } else {
                    return "1.1";
                }
            },
            
            makeUriWithWidth: function (uri, width, version) {
                uri = uri.replace(/\/$/, '');
                if (version[0] == '1') {
                    return uri + '/full/' + width + ',/0/native.jpg';
                } else {
                    return uri + '/full/' + width + ',/0/default.jpg';
                }
            },
            
            getImageHostUrl: function (json) {
                var regex,
                matches =[];
                
                if (! json.hasOwnProperty('image_host')) {
                    
                    json.image_host = json.tilesUrl || json[ '@id'] || '';
                    
                    if (json.hasOwnProperty('identifier')) {
                        regex = new RegExp('/?' + json.identifier + '/?$', 'i');
                        json.image_host = json.image_host.replace(regex, '');
                    } else {
                        regex = new RegExp('(.*)\/(.*)$');
                        matches = regex.exec(json.image_host);
                        
                        if (matches.length > 1) {
                            json.image_host = matches[1];
                            json.identifier = matches[2];
                        }
                    }
                }
                
                return json.image_host;
            }
        };
    }
    (Desp));
    
    /**
     * Manifest
     */
    
    (function ($) {
        
        $.Manifest = function (manifestUri, location) {
            if (manifestUri.indexOf('info.json') !== -1) {
                // The following is an ugly hack. We need to finish the
                // Manifesto utility library.
                // See: https://github.com/IIIF/manifesto
                //
                // If manifestUri is not a string, then
                // it's an object, namely a light-weight
                // dummy manifest wrapped around the
                // contents of an an info.json response.
                //
                // The wrapper is still going to need these
                // accessor methods. We can just set the
                // jsonLd directly, and the request needs to
                // be a jQuery deferred object that is completed
                // imediately upon creation. This allows
                // components listening for this request to finish
                // to react immediately without having to be
                // re-written.
                jQuery.extend(true, this, {
                    jsonLd: null,
                    location: location,
                    uri: manifestUri,
                    request: null
                });
                
                this.initFromInfoJson(manifestUri);
            } else {
                jQuery.extend(true, this, {
                    jsonLd: null,
                    location: location,
                    uri: manifestUri,
                    request: null
                });
                
                this.init(manifestUri);
            }
        };
        
        $.Manifest.prototype = {
            init: function (manifestUri) {
                var _this = this;
                this.request = jQuery.ajax({
                    url: manifestUri,
                    dataType: 'json',
                    async: true
                });
                this.request.done(function (jsonLd) {
                    _this.jsonLd = jsonLd;
                    
                    
                    // attention attention
                    var canvases = _this.getCanvases();
                    _this.hashes = jQuery(canvases).map(function () {
                        return this[ '@id'].replace(/.*\/canvas\//, '');
                    }). get ();
                    
                    
                    var vwr_element = jQuery(document.getElementById(options.id));
                    var vwr_offset = vwr_element.offset().top;
                    
			console.log(_this.hashes);

                    jQuery('body').scrollTheEdition({
                        targets: _this.hashes,
                        offset: 100
                    });
                    
                    if (window.location.hash) {
                        allTheThingsThatChangeOnHashChange();
                        window.location.hash = window.location.hash;
                    } else {
                    };
                    
                    
                    
                    jQuery('body').on('click', function () {
                        jQuery(this).off('click');
                    });
                });
            },
            initFromInfoJson: function (infoJsonUrl) {
                var _this = this;
                this.request = jQuery.ajax({
                    url: infoJsonUrl,
                    dataType: 'json',
                    async: true
                });
                
                this.request.done(function (jsonLd) {
                    _this.jsonLd = _this.generateInfoWrapper(jsonLd);
                });
            },
            getThumbnailForCanvas: function (canvas, width) {
                var version = "1.1",
                service,
                thumbnailUrl;
                
                // Ensure width is an integer...
                width = parseInt(width, 10);
                
                // Respecting the Model...
                if (canvas.hasOwnProperty('thumbnail')) {
                    // use the thumbnail image, prefer via a service
                    if (typeof (canvas.thumbnail) == 'string') {
                        thumbnailUrl = canvas.thumbnail;
                    } else if (canvas.thumbnail.hasOwnProperty('service')) {
                        // Get the IIIF Image API via the @context
                        service = canvas.thumbnail.service;
                        if (service.hasOwnProperty('@context')) {
                            version = $.Iiif.getVersionFromContext(service[ '@context']);
                        }
                        thumbnailUrl = $.Iiif.makeUriWithWidth(service[ '@id'], width, version);
                    } else {
                        thumbnailUrl = canvas.thumbnail[ '@id'];
                    }
                } else {
                    // No thumbnail, use main image
                    var resource = canvas.images[0].resource;
                    service = resource[ 'default'] ? resource[ 'default'].service: resource.service;
                    if (service.hasOwnProperty('@context')) {
                        version = $.Iiif.getVersionFromContext(service[ '@context']);
                    }
                    thumbnailUrl = $.Iiif.makeUriWithWidth(service[ '@id'], width, version);
                }
                return thumbnailUrl;
            },
            getCanvases: function () {
                var _this = this;
                return _this.jsonLd.sequences[0].canvases;
            },
            
            // *** gs: get all info.jsons for osd TODO rename
            getCanvasesInfos: function () {
                var _this = this;
                var canvases = _this.getCanvases();
                
                // hell maybe use iiif.getImageUrl
                var canvasesInfo = jQuery(canvases).map(function () {
                    var imageUrl = $.Iiif.getImageUrl(this);
                    return imageUrl;
                }). get ();
                return canvasesInfo;
            },
            
            
            getAnnotationsListUrl: function (canvasId) {
                var _this = this;
                var canvas = jQuery.grep(_this.getCanvases(), function (canvas, index) {
                    return canvas[ '@id'] === canvasId;
                })[0];
                
                if (canvas && canvas.otherContent) {
                    return canvas.otherContent[0][ '@id'];
                } else {
                    return false;
                }
            },
            getStructures: function () {
                var _this = this;
                return _this.jsonLd.structures;
            },
            generateInfoWrapper: function (infoJson) {
                // Takes in info.json and creates the
                // dummy manifest wrapper around it
                // that will allow it to behave like a
                // manifest with one canvas in it, with
                // one image on it. Some of the metadata
                // of the image will be used as the
                // label, and so on, of the manifest.
                var dummyManifest = {
                    '@context': "http://www.shared-canvas.org/ns/context.json",
                    '@id': infoJson[ '@id'],
                    '@type': 'sc:Manifest',
                    label: infoJson[ '@id'].split('/')[infoJson[ '@id'].split('/').length -1],
                    sequences:[ {
                        '@id': infoJson[ '@id'] + '/sequence/1',
                        '@type': 'sc:Sequence',
                        canvases:[ {
                            '@id': infoJson[ '@id'] + '/sequence/1/canvas/1',
                            '@type': 'sc:Canvas',
                            width: infoJson.width,
                            height: infoJson.height,
                            images:[ {
                                '@id': infoJson[ '@id'] + '/sequence/1/canvas/1/image/1',
                                '@type': 'sc:image',
                                'motivation': 'sc:painting',
                                resource: {
                                    '@id': infoJson,
                                    '@type': "dctypes:Image",
                                    format: "image/jpeg",
                                    height: infoJson.width,
                                    width: infoJson.height,
                                    service: {
                                        '@id': infoJson[ '@id'],
                                        '@context': infoJson[ '@context'],
                                        'profile': infoJson.profile
                                    }
                                }
                            }]
                        }]
                    }]
                };
                
                return dummyManifest;
            }
        };
    }
    (Desp));
    
    //////////////
    // ***** osd//
    //////////////
    
    ////////////////// ********* edition.js ends here
    
    var editionConfig = {
        "viewerId": "vwr-content",
        "manifestUri": options.pid + "/sdef:IIIF/getManifest"
    };
    
    var edition = Desp(editionConfig);
    
    /**
     * all the things that change on hash change
     */
    
    // TODO make offset a constant so that the vwr and
    // the beginning of the text are always aligned


    $('.openseadragon-container div[title="Previous page"], .openseadragon-container div[title="Next page"]').click(function(){

        console.log("hallo2");

        var hash = window.location.hash.substring(1);
        var target = document.getElementById(hash);

        var nav = jQuery('nav');

        //test for bootstrap 3 and 4 classes
        if(nav.hasClass('navbar-static-top') || nav.hasClass('affix-top') || nav.hasClass('sticky-top') || nav.hasClass('fixed-top') || (nav.css('position') === 'fixed')){

            jQuery(window).scrollTop(jQuery(target).offset().top - jQuery('nav').height());

        }



    });

    // Checks if Chrome is used
    if(navigator.vendor.includes('Google')===true){
        $('.openseadragon-container div[title="Previous page"], .openseadragon-container div[title="Next page"]').bind('click',function(){

            var hash = window.location.hash.substring(1);

            var hashes = edition.manifest.hashes;
            var thisCanvasPosition = hashes.indexOf(hash);
            if (viewer.isFullPage() == false) {
                viewer.goToPage(thisCanvasPosition);
            }
            var target = document.getElementById(hash);


            var nav = $('nav');

            // checks if nav is fixed
            if(nav.hasClass('navbar-static-top') || nav.hasClass('affix-top') || nav.hasClass('sticky-top') || nav.hasClass('fixed-top') || (nav.css('position') === 'fixed')){

                $(window).scrollTop($(target).offset().top - $('nav').height());

            }

        });
    }

    // Check if mouse is over seadragon container / Works only with FireFox and Edge
    let mouseOverDragon_flag = undefined;
    let keyPressInDragon = undefined;

    //Check if browser is NOT Chrome
    if(navigator.vendor.includes('Google')===false){
        mouseOverDragon_flag = false;
        $('#vwr-content').hover(function(){
            mouseOverDragon_flag = true;
        },function(){
            mouseOverDragon_flag = false;
        });

        // Check if key Down while mouse over container.
        keyPressInDragon = false;
        $(document).keydown(function(){
            if(mouseOverDragon_flag === true)keyPressInDragon = true;
        });
        $(document).keyup(function(){
            keyPressInDragon = false;
        });
    }

    function allTheThingsThatChangeOnHashChange () {
       
        var hash = window.location.hash.substring(1);
        
        var hashes = edition.manifest.hashes;
        var thisCanvasPosition = hashes.indexOf(hash);
        if (viewer.isFullPage() == false) {
            viewer.goToPage(thisCanvasPosition);
        }
        
        // $(window).scrollTop(jTarget.offset.top-100);
        var target = document.getElementById(hash);
        if(typeof options.paddingTop != 'undefined'){
            //$(target).css('padding-top', options.paddingTop);
        } else {

            //Check for NOT Chrome
            if(navigator.vendor.includes('Google')===false){

                if(mouseOverDragon_flag === true && (keyPressInDragon === false)){
                    // Check if Nav is fixed
                    let nav = $('nav');
                    if(nav.hasClass('navbar-static-top') || nav.hasClass('affix-top') || nav.hasClass('sticky-top') || nav.hasClass('fixed-top') || (nav.css('position') === 'fixed')){
                        $(window).scrollTop($(target).offset().top - $('nav').height());
                    }
                }

            }

        }
    };
    
    
    window.onhashchange = allTheThingsThatChangeOnHashChange;
    
    viewer.addHandler('page', function (event) {
        var thisCanvasPosition = event.page;
        var hashes = edition.manifest.hashes;
        var hash = '#' + hashes[thisCanvasPosition];
        var currentHash = window.location.hash;
        if (hash != currentHash) {
            window.location.replace(hash);
        }


    });
}