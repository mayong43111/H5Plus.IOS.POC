document.addEventListener( "plusready",  function(){
    var    JIM = 'jim',
    B = window.plus.bridge;
    var jim = {
        PluginTestFunction : function (Argus1, Argus2, successCallback, errorCallback ){
            var success = typeof successCallback !== 'function' ? null : function(args){
                successCallback(args);
            },
            fail = typeof errorCallback !== 'function' ? null : function(code){
                errorCallback(code);
            };
            callbackID = B.callbackId(success, fail);

            return B.exec(JIM, "PluginTestFunction", [callbackID, Argus1, Argus2]);
        }
    };
    window.plus.jim = jim;
}, true );
