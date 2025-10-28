server {
    server_name sentry-nginx.practodev.com;
    listen 443 ssl;

    location /oauth2/ {
        proxy_pass http://localhost:4180;
        include proxy_params;
        proxy_set_header X-Auth-Request-Redirect "$scheme://$host$request_uri";
    }

    location = /oauth2/auth {
        proxy_pass http://localhost:4180;
        include proxy_params;
        proxy_set_header Content-Length   "";
        proxy_pass_request_body           off;
    }


}


server {
    server_name accounts-nginx.practodev.com;
    listen 443 ssl;

    set $upstream_accounts_0 http://nodes-k8sg.practodev.com:31116;
    set $upstream_accounts_1 nodes-k8sg.practodev.com:30971;


    location /profile_picture/ {
        error_page 404 403 =200 /static/images/profile.png;
        rewrite ^/profile_picture/(.*)$ /$1 break;
        proxy_pass https://staging-factory-practo-accounts.s3-ap-southeast-1.amazonaws.com;
        proxy_intercept_errors on;
    }

    location /static {
        proxy_pass $upstream_accounts_0;
    }

    location = /.well-known/apple-app-site-association {
        rewrite ^ /apple-app-site-association last;
    }

    location = /apple-app-site-association {
        rewrite ^(.*)$ /app/staging$1 break;
        proxy_ssl_protocols  TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        proxy_pass https://staging-factory-practo-accounts.s3-ap-southeast-1.amazonaws.com;
        proxy_intercept_errors on;
    }

    location /payment/static {
        proxy_pass $upstream_accounts_0;
    }

    location / {
        include uwsgi_params;
        uwsgi_pass $upstream_accounts_1;
    }
}


### Testing if the client is a mobile or a desktop.
### The selection is based on the usual UA strings for desktop browsers.

## Testing a user agent using a method that reverts the logic of the
## UA detection. Inspired by notnotmobile.appspot.com.
map $http_user_agent $fabric_is_mobile_1 {
  default 0;
  "~*(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|pixel|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino" 1;
}

map $http_user_agent $fabric_is_mobile {
  default $fabric_is_mobile_1;
  "~*^(1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-)" 1;
}

map $http_accept $fabric_is_header_not_json {
  default 1;
  ~application\/json 0;
}

map $args $fabric_is_not_json {
  default $fabric_is_header_not_json;
  ~json=true 0;
}

map $http_user_agent $fabric_is_practo_crawl_bot_and_not_json {
  default 0;
  "practoVbQg9zVGDmRvMAvArogetbotsapphire" $fabric_is_not_json;
}

map $fabric_is_mobile $fabric_is_topaz {
  default 0;
  0 $fabric_is_not_json;
}

map $fabric_is_mobile $fabric_is_sapphire {
  default $fabric_is_practo_crawl_bot_and_not_json;
  1 $fabric_is_not_json;
}

split_clients "${time_local}" $profile_traffic_is_consumer_ui {
  50%   1 ;
  *      0;
}

map $cookie_is_profile_from_consumer_ui $is_consumer_ui_profile_cookie_set {
  "true"  1;
  "false" 0;
  default 2;
}

map $arg_is_consumer_ui $fabric_profile_forced_to_consumer_ui {
  "true" 1;
  "false" 0;
  default 2;
}

map "${fabric_is_topaz}${fabric_is_sapphire}${fabric_profile_forced_to_consumer_ui}${is_consumer_ui_profile_cookie_set}${profile_traffic_is_consumer_ui}" $profile_upstream {
  "~^1....$" "topaz";
  "~^00...$" "fabric";
  "~^010..$" "sapphire";
  "~^011..$" "consumer_ui";
  "~^0120.$" "sapphire";
  "~^0121.$" "consumer_ui";
  "~^01220$" "sapphire";
  "~^01221$" "consumer_ui";
  default    "sapphire";
}


server {
    server_name www-nginx.practodev.com;
    listen 443 ssl;


    set $upstream_nav http://nodes-k8sg.practodev.com:30831;























    set $upstream_marketplace_api http://nodes-k8sg.practodev.com:32148;
























    set $upstream_consumer_ui http://nodes-k8sg.practodev.com:31674;








    location = /appointments/list {
      include proxy_params;
      #use sapphire
      if ($fabric_is_sapphire = 1) {
        proxy_pass $upstream_sapphire_app;
      }

      #use topaz
      if ($fabric_is_sapphire = 0) {
        proxy_pass $upstream_topaz;
      }
    }

    location ~ ^/appointment {
      include proxy_params;

      #use sapphire
      if ($fabric_is_sapphire = 1) {
        proxy_pass $upstream_sapphire_app;
      }

      #use topaz
      if ($fabric_is_sapphire = 0) {
        proxy_pass $upstream_topaz;
      }
    }


    location /cerebro/autocomplete {
      proxy_set_header Host search-nginx.practodev.com;
      proxy_pass $upstream_search_practo/autocomplete$is_args$query_string;
    }

    location /cerebro/v2/autocomplete {
      proxy_set_header Host search-nginx.practodev.com;
      proxy_pass $upstream_search_practo/v2/autocompleteindex$is_args$query_string;
    }

    location /cerebro/autocomplete/v3/keyword {
      proxy_set_header Host search-nginx.practodev.com;
      proxy_pass $upstream_search_practo/autocomplete/v3/keyword$is_args$query_string;
    }

    location /cerebro/v3/autocomplete {
      proxy_set_header Host search-nginx.practodev.com;
      proxy_pass $upstream_search_practo/v3/autocomplete$is_args$query_string;
    }









    location /marketplace-api {
      include proxy_params;
      proxy_pass $upstream_marketplace_api;
    }
    location ~ ^/s3_domain_payment_invoice(?P<s3_path_payment_invoice>.*)$ {
    internal;
    proxy_ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
    proxy_pass          https://s3-ap-southeast-1.amazonaws.com$s3_path_payment_invoice$is_args$args;
    proxy_hide_header   Content-Disposition;
    proxy_hide_header   Cache-Control;
    }
    location /dev-nhs-abha/ {
        proxy_ssl_protocols  TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        proxy_pass https://s3.ap-south-1.amazonaws.com;
        proxy_set_header Content-Type '';
        internal;
    }































    location /dxapi {
      add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
      add_header Access-Control-Allow-Origin "https://drive-nginx.practodev.com";
      add_header Access-Control-Allow-Methods "GET, POST, PATCH, DELETE, OPTIONS";
      add_header Access-Control-Allow-Headers 'x-profile-token,DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
      add_header Access-Control-Allow-Credentials 'true' always;
      include proxy_params;
      proxy_pass https://ec2-65-2-189-133.ap-south-1.compute.amazonaws.com;
    }






    # Redirect to Dentist Listing
    location = /redirect-listing/dentist {
      return 301 https://www-nginx.practodev.com/$geoip_city/dentist;
    }



    # Opening establishment feedback page on Topaz
    location  ~* ^/[^/]+/(clinic|hospital)/[^/]+/feedback$ {

    }


    # Mweb & Dweb: Clinic and Hospital Page URLs for doctors, recent, insurances, recommended, services ,amp, faq, and other centers
    location  ~* ^/[^/]+/(clinic|hospital)/[^/]+/(doctors|recent|insurances|recommended|services|reviews|amp|faq|other-centers)$ {
      include proxy_params;




    }

    # Clinic and Hospital Profile URL & establishment speciality page URL
    location ~* ^/[^/]+/(clinic|hospital)/[^/]+(/[^/]+)?$ {
      include proxy_params;


                        if ($fabric_is_sapphire = 1) {
        # Cron/Worker flow for establishemnt profile page
        # Listen to SQS que for establishemnt profiles
        # Builds static html files for current batch of que items and validates all the generated static html files
        # Upload the successfull html files to S3 bucket
        # Push the unsuccessfull que items to DLQ queue

        # Request flow for establishemnt profile page
        # Request comes to nginx (HTML)
                                # nginx first tries to fetch HTML from S3 & serve if found
                                # nginx fallback to Consumer UI Nextjs server if S3 returns 404

        # S3 404 cases
        # 1. establishment not yet picked by worker
        # 2. establishment picked but failed to complete worker process(API failures, build failures, html validation failures, aws lib communication failures)

        # Request comes to nginx (Assets)
        # Serves assets from S3 bucket if HTML is served from S3
        # Serves assets from Consumer UI Nextjs server if HTML is served from Consumer UI Nextjs server
        # Also sets the headers(SERVED-FROM, S3-URL) for debugging

                                # Extract city, type and name from the URL
                                set $consumer_ui_city $1;
                                set $consumer_ui_profile_type $2;
                                set $consumer_ui_slug $3;

                                # S3 bucket and folder variables
                                # AWS S3 configuration(production):
                                # set $consumer_ui_s3_bucket "practo-dev-mumbai-static-apps";
                                # set $consumer_ui_s3_endpoint "s3.ap-south-1.amazonaws.com";

                                # AWS LocalStack S3 configuration:
                                set $consumer_ui_s3_bucket "localstack-bucket";
                                set $consumer_ui_s3_endpoint "localhost:4566";
                                set $consumer_ui_s3_folder_name "consumer-ui/export-assets";

                                # Build the full S3 URL that will be tried
                                set $consumer_ui_s3_url "http://$consumer_ui_s3_endpoint/$consumer_ui_s3_bucket/$consumer_ui_s3_folder_name/$consumer_ui_city/$consumer_ui_profile_type/$consumer_ui_slug.html";

                                # Track that request is serving from S3
                                set $consumer_ui_served_from "AWS(SSG)";

                                # Rewrite to S3 path with .html extension
                                rewrite ^ /$consumer_ui_s3_folder_name/$consumer_ui_city/$consumer_ui_profile_type/$consumer_ui_slug.html break;

                                proxy_intercept_errors on;
                                error_page 404 = @consumer_ui_establishment_profile_fallback;

                                proxy_pass http://$consumer_ui_s3_endpoint;
                                proxy_set_header Host $consumer_ui_s3_bucket;
                                proxy_set_header X-Real-IP $remote_addr;

                                # Add header to identify S3-served content
                                add_header SERVED-FROM $consumer_ui_served_from always;
                                add_header S3-URL $consumer_ui_s3_url always;
                        }



    }

    # Consumer UI Routes

    location ^~ /consumer-ui/ {
      include proxy_params;
      proxy_pass $upstream_consumer_ui;
    }

    location ~* /ai-consult-story {
      include proxy_params;
      proxy_pass $upstream_consumer_ui;
    }

    # Handle fallback URL to serve the request from consumer-ui upstream
    location ^~ /consumer_ui_fallback/ {
      # Informs nginx config that this block is for internal usage only. It won't be accesible from outside
      internal;

      include proxy_params;
      rewrite ^/consumer_ui_fallback(/.*)$ /$1 break;
      proxy_pass $upstream_consumer_ui;
    }

    # Handle fallback to consumer-ui Next server for establishment profile when S3 returns 404
    location @consumer_ui_establishment_profile_fallback {
      internal;


      if ($fabric_is_sapphire = 1) {
        set $consumer_ui_served_from "NEXT(SSR)";
        proxy_pass $upstream_consumer_ui;

        add_header SERVED-FROM $consumer_ui_served_from always;
        add_header S3-URL $consumer_ui_s3_url always;
      }

    }

    # Assets for consumer-ui established profile pages served from S3 bucket
    # location ~ ^/consumer-ui-assets/(?P<path>.*) {
    location ~ ^/localstack-bucket/consumer-ui/export-assets/(?P<path>.*) {
      #resolver 8.8.8.8;
      # AWS S3 configuration:
      # set $consumer_ui_s3_bucket "practo-dev-mumbai-static-apps";
      # set $consumer_ui_s3_endpoint "s3.ap-south-1.amazonaws.com";
      # LocalStack S3 configuration:
      set $consumer_ui_s3_bucket "localstack-bucket";
      set $consumer_ui_s3_endpoint "localhost:4566";
      set $consumer_ui_s3_folder_name "consumer-ui/export-assets";
      set $backend $consumer_ui_s3_endpoint;

      #proxy_set_header  Host    $backend;
      set $full_url http://$backend/$consumer_ui_s3_bucket/$consumer_ui_s3_folder_name/$path;
      proxy_pass $full_url;
    }







      location ^~ /nav {
        include proxy_params;
        rewrite ^/nav/(.*) /$1 break;
        proxy_pass $upstream_nav;
      }




    # consumer home


    # space ui





}


server {
    server_name nav-nginx.practodev.com;
    listen 443 ssl;


    set $upstream_nav http://nodes-k8sg.practodev.com:30831;


    location / {
        include proxy_params;
        proxy_pass $upstream_nav;
    }
}
