#!/bin/bash
set -e


echo "=============================="
echo " Hermes Agent"
echo "=============================="


echo "MODEL:"
echo "$OPENAI_MODEL"


echo "BASE:"
echo "$OPENAI_BASE_URL"


echo "KEY LENGTH:"
echo "${#OPENAI_API_KEY}"


mkdir -p /root/.hermes


envsubst < /tmp/config.yaml > /root/.hermes/config.yaml


echo "Hermes config installed"


grep -A6 "custom_providers" /root/.hermes/config.yaml || true


cd /opt/hermes-agent


echo "Running Hermes..."


RESULT=$(uv run hermes \
    --cli \
    -z "$@"
)


echo "========== Hermes Result =========="

echo "$RESULT"


mkdir -p /output


cat > /output/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">

<title>Hermes News</title>

<style>
body {
    font-family: sans-serif;
    margin: 40px;
    line-height: 1.6;
}

pre {
    white-space: pre-wrap;
}

</style>

</head>

<body>

<h1>Hermes Generated Result</h1>

<pre>
$RESULT
</pre>


</body>

</html>
EOF


chmod 644 /output/index.html


echo "Created:"
ls -l /output/index.html
