#!/bin/sh

# Copyright (c) 2016 Jeff Schornick <code@schornick.org>
# Licensed under the MIT License
# http://www.opensource.org/licenses/mit-license.php

# set to 'echo' to enable debugging
${DEBUG:=:}

API_URL=https://api.digitalocean.com/v2

api_call ()
{
    $DEBUG "api_call ( $* )" >&2
    resource=$(echo $* | tr ' ' /)
    $DEBUG resource: $resource >&2
    AUTH_HEADER="Authorization: Bearer ${API_TOKEN}"
    ${WGET} --method=GET --header "${AUTH_HEADER}" ${API_URL}/${resource}
}

api_call_with_data ()
{
    $DEBUG "api_call_with_data ( $* )" >&2
    data=$1
    shift
    resource=$(echo $* | tr ' ' /)
    $DEBUG Resource: $resource >&2
    $DEBUG Data: $data >&2
    AUTH_HEADER="Authorization: Bearer ${API_TOKEN}"
    ${WGET} --method=PUT --header "${AUTH_HEADER}" --header "Content-Type: application/json" ${API_URL}/${resource} --body-data=$data
}

get_record_id ()
{
    domain=$1
    name=$2
    $DEBUG "get_domain_id ( $* )" >&2
    if [ -e /usr/bin/jq ]; then
        $DEBUG "Using jq for filtering" >&2
        filter="jq '.domain_records[] | select(.name == \"${name}\") | .id'"
    elif [ -e /usr/bin/jsonfilter ]; then
        $DEBUG "Using jsonfilter for filtering" >&2
        filter="jsonfilter -e '@[\"domain_records\"][@.name=\"${name}\"].id'"
    else
        echo "Can't call JSON filter!"
        exit 1
    fi

    out=$(api_call domains $domain records)
    result=$(echo $out | eval ${filter})
    echo $result
}

get_record_ip ()
{
    domain=$1
    name=$2
    $DEBUG "get_domain_id ( $* )" >&2
    if [ -e /usr/bin/jq ]; then
        $DEBUG "Using jq for filtering" >&2
        filter="jq '.domain_records[] | select(.name == \"${name}\") | .data'"
    elif [ -e /usr/bin/jsonfilter ]; then
        $DEBUG "Using jsonfilter for filtering" >&2
        filter="jsonfilter -e '@[\"domain_records\"][@.name=\"${name}\"].data'"
    else
        echo "Can't call JSON filter!"
        exit 1
    fi

    out=$(api_call domains $domain records)
    result=$(echo $out | eval ${filter} | tr -d \")
    echo $result
}

set_record_ip ()
{
    domain=$1
    record_id=$2
    ip_addr=$3
    $DEBUG "set_domain_id ( $* )" >&2
    api_call_with_data {\"data\":\"$ip_addr\"} domains $domain records $record_id
}

