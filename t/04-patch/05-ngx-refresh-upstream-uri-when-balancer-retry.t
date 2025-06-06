# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;

#worker_connections(1014);
#master_on();
#workers(2);
#log_level('warn');

repeat_each(2);
#repeat_each(1);

plan tests => repeat_each() * (blocks() * 2);

#no_diff();
#no_long_string();
run_tests();

__DATA__
=== TEST 1: recreate_request refresh upstream uri variable
--- http_config
    lua_package_path "../lua-resty-core/lib/?.lua;;";

    server {
        listen 127.0.0.1:$TEST_NGINX_RAND_PORT_1;

        location / {
            content_by_lua_block {
                ngx.req.read_body()
                local body = ngx.req.get_body_data()
                ngx.say(ngx.var.uri)
            }
        }
    }

    upstream foo {
        server 127.0.0.1:$TEST_NGINX_RAND_PORT_1 max_fails=3;

        balancer_by_lua_block {
            local bal = require "ngx.balancer"
            ngx.req.set_body_data("hello world")
            ngx.var.upstream_uri = "/ttttt"
            assert(bal.recreate_request())
        }
    }

--- config
    set $upstream_uri "/t";
    location = /t {
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_pass http://foo$upstream_uri;
    }
--- request
GET /t
--- error_code: 200
--- response_body
/ttttt
