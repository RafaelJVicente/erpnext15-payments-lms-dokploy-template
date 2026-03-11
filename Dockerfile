FROM frappe/erpnext:version-15

USER root
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN bench get-app --branch version-15 payments https://github.com/frappe/payments && \
    bench get-app --branch main lms https://github.com/frappe/lms