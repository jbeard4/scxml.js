/*
     Copyright 2011-2012 Jacob Beard, INFICON, and other SCION contributors

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

"use strict";

var scxmlToScjson = require('../compiler/scxml-to-scjson'),
    scjsonToModule = require('../compiler/scjson-to-module'),
    inlineSrcs = require('./transform/inline-srcs'),
    pm = require('./platform-bootstrap/platform');

function documentStringToModel(url,docString,cb,context){

    var scJson = scxmlToScjson(docString);

    try {

        //do whatever transforms
        //inline script tags
        //platformGet may be undefined, and we can continue without it, hence the guard
        if(pm.platform.getResourceFromUrl){
            inlineSrcs(url,scJson,context,function(errors){
                if(errors){
                    //treat script download errors as fatal
                    //pass through a single error - aggregate if there's more than one
                    cb(errors.length === 1 ?
                            errors[0].err :
                            new Error(
                                'Script download errors : \n' +
                                    errors.map(function(oErr){return oErr.url + ': ' + oErr.err.message;}).join('\n')));
                }else{
                    //otherwise, attempt to convert document to model object
                    createModule(url,scJson,context,cb);
                }
            });
        }else{
            createModule(url,scJson,context,cb);
        }
    }catch(e){
        cb(e);
    }
}

function createModule(url,scJson,context,cb){

    if(pm.platform.debug) console.log('scjson',JSON.stringify(scJson,4,4)); 

    var jsModuleString = scjsonToModule(scJson);
    if(pm.platform.debug) console.log('jsModuleString\n',jsModuleString); 

    var model = pm.platform.module.eval(jsModuleString,url,context);     //TODO: use a platform-native eval? this is where we would pass in require
    if(pm.platform.debug) console.log('model',model);

    cb(null,model);
}

module.exports = documentStringToModel;
