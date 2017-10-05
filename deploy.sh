#!/bin/bash
set -x
rsync -auP public_html deploy@api.jacksonargo.com:/var/www/html/www.jacksonargo.com
