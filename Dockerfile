FROM frappe/erpnext:version-15

USER root
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN mkdir -p sites && \
    cat > sites/common_site_config.json <<'EOF'
{
  "socketio_port": 9000
}
EOF

RUN bench get-app --branch version-15 payments https://github.com/frappe/payments && \
    bench get-app --branch main lms https://github.com/frappe/lms