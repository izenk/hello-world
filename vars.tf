variable "nginx_script" {
  type = "string"
  default = <<EOF
apk update && \
    apk add nginx curl unzip && \
    rm -rf /var/cache/apk/*

curl -Lo /tmp/consul_template_0.15.0_linux_amd64.zip https://releases.hashicorp.com/consul-template/0.15.0/consul-template_0.15.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.15.0_linux_amd64.zip && \
    mv consul-template /bin

export CONTAINERPILOT_CHECKSUM=6da4a4ab3dd92d8fd009cdb81a4d4002a90c8b7c \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/3.0.0/containerpilot-3.0.0.tar.gz" \
    && echo "6da4a4ab3dd92d8fd009cdb81a4d4002a90c8b7c  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /bin \
    && rm /tmp/containerpilot.tar.gz

chmod +x /bin/reload-nginx.sh || true

EOF
}

variable nginx_containerpilot {
  type = "string"
  default = <<EOF
{
  consul: "consul:8500",
  logging: {
    level: "DEBUG",
    format: "text"
  },
  jobs: [
    {
      // without a "when" field this will start first
      name: "preStart",
      exec: "/bin/reload-nginx.sh preStart"
    },
    {
      name: "nginx",
      port: 80,
      interfaces: ["eth1", "eth0"],
      exec: "nginx",
      when: {
        source: "preStart",
        once: "exitSuccess"
      },
      health: {
        exec: "/usr/bin/curl -o /dev/null --fail -s http://localhost/health",
        interval: 10,
        ttl: 25
      }
    },
    {
      name: "onchange-hello",
      exec: "/bin/reload-nginx.sh onChange",
      when: {
        source: "watch.hello",
        each: "changed"
      }
    },
    {
      name: "onchange-world",
      exec: "/bin/reload-nginx.sh onChange",
      when: {
        source: "watch.world",
        each: "changed"
      }
    }
  ],
 watches: [
    {
      name: "hello",
      interval: 3
    },
    {
      name: "world",
      interval: 3
    }
  ]
}
EOF
}

variable "reload-nginx" {
  type = "string"
  default = <<EOF
#!/bin/sh

# Render Nginx configuration template using values from Consul,
# but do not reload because Nginx has't started yet
preStart() {
    consul-template \
        -once \
        -consul consul:8500 \
        -template "/etc/containerpilot/nginx.conf.ctmpl:/etc/nginx/nginx.conf"
}

# Render Nginx configuration template using values from Consul,
# then gracefully reload Nginx
onChange() {
    consul-template \
        -once \
        -consul consul:8500 \
        -template "/etc/containerpilot/nginx.conf.ctmpl:/etc/nginx/nginx.conf:nginx -s reload"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        onChange
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    onChange
    exit
done
EOF
}

variable "nginx_index" {
  type = "string"
  default = <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
  <section class="wrapper">
    <h1></h1>
    <h2></h2>
  </section>
</body>
<script>
  window.onload = function () {
    setHello();
    setWorld();
  };

  function setHello () {
    window.fetch('/hello').then(function (res) {
      return res.text();
    }).then(function (val) {
      const h1 = document.getElementsByTagName('h1')[0];
      h1.innerHTML = val + h1.innerHTML;
    });
  }

  function setWorld () {
    window.fetch('/world').then(function (res) {
      return res.text();
    }).then(function (val) {
      const h2 = document.getElementsByTagName('h2')[0];
      h2.innerHTML = val + h2.innerHTML;
    });
  }
</script>
</html>
EOF
}

variable "style" {
  type = "string"
  default = <<EOF
progress,sub,sup{vertical-align:baseline}button,hr,input{overflow:visible}[type=checkbox],[type=radio],legend{box-sizing:border-box;padding:0}html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,details,figcaption,figure,footer,header,main,menu,nav,section,summary{display:block}audio,canvas,progress,video{display:inline-block}audio:not([controls]){display:none;height:0}[hidden],template{display:none}a{background-color:transparent;-webkit-text-decoration-skip:objects}a:active,a:hover{outline-width:0}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:bolder}dfn{font-style:italic}h1{font-size:2em;margin:.67em 0}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative}sub{bottom:-.25em}sup{top:-.5em}img{border-style:none}svg:not(:root){overflow:hidden}code,kbd,pre,samp{font-family:monospace,monospace;font-size:1em}figure{margin:1em 40px}hr{box-sizing:content-box;height:0}button,input,select,textarea{font:inherit;margin:0}optgroup{font-weight:700}button,select{text-transform:none}[type=reset],[type=submit],button,html [type=button]{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:ButtonText dotted 1px}fieldset{border:1px solid silver;margin:0 2px;padding:.35em .625em .75em}legend{color:inherit;display:table;max-width:100%;white-space:normal}textarea{overflow:auto}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-cancel-button,[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-input-placeholder{color:inherit;opacity:.54}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}

body {background-color:#4682B4;}
.wrapper {max-width: 1000px; padding: 10px; margin: 0 auto; text-align: center;}
h1 {color:#fff; display: inline-block; padding: 10px 0; font-size: 2em; }
h2 {color:#7FFF00; display: inline-block; padding: 10px 0; font-size: 2em;}
EOF
}

variable "nginx" {
  type = "string"
  default = <<EOF
daemon off;
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  _;

        root /usr/share/nginx/html;

        location /health {
            # requires http_stub_status_module
            stub_status;
            allow 127.0.0.1;
            deny all;
        }
    }
}
EOF
}

variable "nginx_ctmpl" {
  type = "string"
  default = <<EOF
daemon off;
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;


    {{ if service "hello" }}
    upstream hello {
        # write the address:port pairs for each healthy Hello node
        {{range service "hello"}}
        server {{.Address}}:{{.Port}};
        {{end}}
        least_conn;
    }{{ end }}

    {{ if service "world" }}
    upstream world {
        # write the address:port pairs for each healthy World node
        {{range service "world"}}
        server {{.Address}}:{{.Port}};
        {{end}}
        least_conn;
    }{{ end }}

    server {
        listen       80;
        server_name  _;

        root /usr/share/nginx/html;

        location /health {
            # requires http_stub_status_module
            stub_status;
            allow 127.0.0.1;
            deny all;
        }

        {{ if service "hello" }}
        location ^~ /hello {
            # strip '/hello' from the request before passing
            # it along to the Hello upstream
            rewrite ^/hello(/.*)$ $1 break;
            proxy_pass http://hello;
            proxy_redirect off;
        }{{end}}

        {{ if service "world" }}
        location ^~ /world {
            # strip '/world' from the request before passing
            # it along to the World upstream
            rewrite ^/world(/.*)$ $1 break;
            proxy_pass http://world;
            proxy_redirect off;
        }{{end}}
    }
}
EOF
}

variable "index_hello" {
  type = "string"
  default = <<EOF
'use strict';

// Load modules

const Http = require('http');


const server = module.exports = Http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Hello');
});

server.listen(3001, () => {
  console.log(`Hello server listening on port ${server.address().port}`);
});
EOF
}

variable "index_world" {
  type = "string"
  default = <<EOF
'use strict';

// Load modules

const Http = require('http');


const server = module.exports = Http.createServer((req, res) => {
  res.writeHead(200);
  res.end('World');
});

server.listen(3002, () => {
  console.log(`World server listening on port ${server.address().port}`);
});
EOF
}


variable "hello_containerpilot" {
  type = "string"
  default = <<EOF
{
  consul: "consul:8500",
  jobs: [
    {
      name: "hello",
      exec: "node /opt/hello/index.js",
      port: 3001,
      health: {
        exec: "/usr/bin/curl -o /dev/null --fail -s http://localhost:3001/",
        interval: 3,
        ttl: 10
      }
    }
  ]
}
EOF
}

variable "world_containerpilot" {
  type = "string"
  default = <<EOF
{
  consul: "consul:8500",
  jobs: [
    {
      name: "world",
      exec: "node /opt/world/index.js",
      port: 3002,
      health: {
        exec: "/usr/bin/curl -o /dev/null --fail -s http://localhost:3002/",
        interval: 3,
        ttl: 10
      }
    }
  ]
}
EOF
}
