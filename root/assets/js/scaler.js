
var ImageScaler = new function() {
    var image_host = ImageScalerConfig.image_host;
    var trigger_url = ImageScalerConfig.trigger_url;
    var max_retries = ImageScalerConfig.max_retries;
    var retry_delay = ImageScalerConfig.retry_delay;
    var pixelratio = window.devicePixelRatio || 1;

    var image_path = function(data) {
        var src = data.src || '_';
        var width = data.width || '_';
        var height = data.height || '_';
        var pixelratio = data.pixelratio || '1';
        var scale = data.scale || '_';
        var type = data.type || '_';
        var salt = data.salt || '_';
        var key = src+width+height+pixelratio+scale+type+salt;
        var hash = this.sha256(key);
        return hash;
    };

    var img_properties = function($el) {
        var data = $el.clone().data();
        data.width = data.width || $el.width() || undefined;
        data.height = data.height || $el.height() || undefined;
        if (!data.pixelratio) data.pixelratio = pixelratio;
        return data;
    };

    var img_reloader_cb = function(el) {
        return function() {
            $(el).attr('src',$(el).attr('src'));
        };
    };
    var img_trigger = function(el) {
        $.post( trigger_url, $(el).data('autoscale') );
    };

    this.scale = function(el) {
        $('img.autoscale',el)
            .attr("src",function() {
                var properties = img_properties($(this));
                $(this).data('autoscale',properties);
                return '//'+image_host+'/'+image_path(properties);
            })
            .on("error", function() {
                var data = $(this).data();
                data.t = data.t ? data.t+1 : 1;
                if ( data.t == 1 )
                    img_trigger(this);
                if ( data.t <= max_retries )
                    setTimeout( img_reloader_cb(this), data.t * retry_delay );
                else
                    $(this).attr('src',$(this).data('src')).off("error");
            })
            .one("load",function() {
                $(this).css("visibility","visible");
            })
        ;
    };

    (function(){var m=8;var k=function(q,t){var s=(q&65535)+(t&65535);var r=(q>>16)+(t>>16)+(s>>16);return(r<<16)|(s&65535)};var e=function(r,q){return(r>>>q)|(r<<(32-q))};var g=function(r,q){return(r>>>q)};var a=function(q,s,r){return((q&s)^((~q)&r))};var d=function(q,s,r){return((q&s)^(q&r)^(s&r))};var h=function(q){return(e(q,2)^e(q,13)^e(q,22))};var b=function(q){return(e(q,6)^e(q,11)^e(q,25))};var p=function(q){return(e(q,7)^e(q,18)^g(q,3))};var l=function(q){return(e(q,17)^e(q,19)^g(q,10))};var c=function(r,s){var E=new Array(1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298);var t=new Array(1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225);var q=new Array(64);var G,F,D,C,A,y,x,w,v,u;var B,z;r[s>>5]|=128<<(24-s%32);r[((s+64>>9)<<4)+15]=s;for(var v=0;v<r.length;v+=16){G=t[0];F=t[1];D=t[2];C=t[3];A=t[4];y=t[5];x=t[6];w=t[7];for(var u=0;u<64;u++){if(u<16){q[u]=r[u+v]}else{q[u]=k(k(k(l(q[u-2]),q[u-7]),p(q[u-15])),q[u-16])}B=k(k(k(k(w,b(A)),a(A,y,x)),E[u]),q[u]);z=k(h(G),d(G,F,D));w=x;x=y;y=A;A=k(C,B);C=D;D=F;F=G;G=k(B,z)}t[0]=k(G,t[0]);t[1]=k(F,t[1]);t[2]=k(D,t[2]);t[3]=k(C,t[3]);t[4]=k(A,t[4]);t[5]=k(y,t[5]);t[6]=k(x,t[6]);t[7]=k(w,t[7])}return t};var j=function(t){var s=Array();var q=(1<<m)-1;for(var r=0;r<t.length*m;r+=m){s[r>>5]|=(t.charCodeAt(r/m)&q)<<(24-r%32)}return s};var n=function(s){var r="0123456789abcdef";var t="";for(var q=0;q<s.length*4;q++){t+=r.charAt((s[q>>2]>>((3-q%4)*8+4))&15)+r.charAt((s[q>>2]>>((3-q%4)*8))&15)}return t};var o=function(s,v){var u=j(s);if(u.length>16){u=c(u,s.length*m)}var q=Array(16),t=Array(16);for(var r=0;r<16;r++){q[r]=u[r]^909522486;t[r]=u[r]^1549556828}var w=c(q.concat(j(v)),512+v.length*m);return c(t.concat(w),512+256)};var i=function(q){q=typeof q=="object"?f(q).val():q.toString();return q};this.sha256=function(q){q=i(q);return n(c(j(q),q.length*m))}})();
}
