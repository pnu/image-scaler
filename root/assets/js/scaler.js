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
        var hash = $.sha256(key);
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
}
