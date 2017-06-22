# Configure the Docker provider
provider "docker" {
  host = "tcp://127.0.0.1:2375"
}

# Create a container
resource "docker_container" "nginx" {
  image = "${docker_image.nginx.latest}"
  name  = "nginx"
#  command = ["ping", "127.0.0.01"]
  command = ["sh","-c", "chmod +x /bin/nginx_cmd.sh && /bin/nginx_cmd.sh && /bin/containerpilot"]
  env = ["CONTAINERPILOT_VER=3.0.0", "CONTAINERPILOT=/etc/containerpilot.json5"]
  links = ["consul"]
  restart = "always"
  must_run = true
  ports { internal = 80, external = 80 }
  upload { content = "${var.nginx_script}", file = "/bin/nginx_cmd.sh"}
  upload { content = "${var.nginx_containerpilot}", file = "/etc/containerpilot.json5"}
  upload { content = "${var.reload-nginx}", file = "/bin/reload-nginx.sh"}
  upload { content = "${var.nginx_index}", file = "/usr/share/nginx/html/index.html"}
  upload { content = "${var.style}", file = "/usr/share/nginx/html/style.css"}
  upload { content = "${var.nginx}", file = "/etc/nginx/nginx.conf"}
  upload { content = "${var.nginx_ctmpl}", file = "/etc/containerpilot/nginx.conf.ctmpl"}  
  depends_on = ["docker_container.consul"]
}

# Create a container
resource "docker_container" "hello" {
  image = "${docker_image.app.latest}"
  name  = "hello"
#  command = ["ping", "127.0.0.01"]
  command = ["sh","-c", "chmod +x /bin/nginx_cmd.sh && /bin/nginx_cmd.sh && /bin/containerpilot"]
  env = ["CONTAINERPILOT_VER=3.0.0", "CONTAINERPILOT=/etc/containerpilot.json5"]
  links = ["consul"]
  restart = "no"
  must_run = true
  ports { internal = 3001, external = 3001 }  
  upload { content = "${var.nginx_script}", file = "/bin/nginx_cmd.sh"}
  upload { content = "${var.hello_containerpilot}", file = "/etc/containerpilot.json5"}
  upload { content = "${var.index_hello}", file = "/opt/hello/index.js"}
  depends_on = ["docker_container.consul"]
}

# Create a container
resource "docker_container" "world" {
  image = "${docker_image.app.latest}"
  name  = "world"
#  command = ["ping", "127.0.0.01"]
  command = ["sh","-c", "chmod +x /bin/nginx_cmd.sh && /bin/nginx_cmd.sh && /bin/containerpilot"]
  env = ["CONTAINERPILOT_VER=3.0.0", "CONTAINERPILOT=/etc/containerpilot.json5"]
  links = ["consul"]
  restart = "no"
  must_run = true
  ports { internal = 3002, external = 3002 }
  upload { content = "${var.nginx_script}", file = "/bin/nginx_cmd.sh"}
  upload { content = "${var.world_containerpilot}", file = "/etc/containerpilot.json5"}
  upload { content = "${var.index_world}", file = "/opt/world/index.js"}
  depends_on = ["docker_container.consul"]
}

# Create a container
resource "docker_container" "consul" {
  image = "${docker_image.consul.latest}"
  name  = "consul"
  restart = "always"
}

resource "docker_image" "nginx" {
  name = "alpine:3.4"
}

resource "docker_image" "app" {
  name = "mhart/alpine-node:latest"
}

resource "docker_image" "consul" {
  name = "consul:latest"
}
